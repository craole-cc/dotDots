{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) attrByPath attrNames isAttrs mapAttrs recursiveUpdate;
  inherit (lib.lists) any concatMap elemAt foldl' head isList length optionals reverseList tail unique;
  inherit (lib.strings) concatStringsSep isString match stringLength substring toUpper toJSON trim;
  inherit (fetchers) fetchSource;
  inherit (strings) hashString showPath;
  inherit (trivial) isEmpty isNotEmpty;
  inherit (debug) requireNonEmpty requireThat;

  schema = import ./schema;

  debug = {
    requireNonEmpty = {
      context,
      path,
      set,
    }: let
      value = attrByPath path null set;
      label = showPath path;
    in
      if value == null
      then throw "${context}: missing required attribute '${label}'"
      else if isEmpty value
      then throw "${context}: required attribute '${label}' must not be empty"
      else true;

    #> Assert an arbitrary condition, with a contextual message on failure
    requireThat = {
      context,
      message,
      condition,
    }:
      if condition
      then true
      else throw "${context}: ${message}";
  };

  fetchers = {
    /**
    Build a fetch spec for a GitHub archive tarball.

    Takes GitHub coordinates and returns the attrset `fetchSource` expects: a
    `url` pointing at the commit archive, plus the inputs echoed back for
    introspection (so callers/debug tooling can see what was requested
    without re-deriving it from the url).

    # Inputs

    `owner`
    : GitHub org/user. String.

    `repo`
    : Repository name. String.

    `rev`
    : Commit hash to pin to — not a branch name; a branch's tarball changes
      under a fixed hash, so `rev` must be a commit for reproducibility.
      String.

    `sha256`
    : Fixed-output hash for reproducibility, or `null` to fetch unpinned.
      Nullable string. Default `null`.

    `type`
    : Source kind, echoed through for downstream consumers (e.g. flake input
      classification). Does not currently affect URL construction — only
      GitHub-shaped archive URLs are built regardless of this value.
      String. Default `"github"`.

    # Type

    ```
    mkGitHubSource :: {
      owner : String,
      repo : String,
      rev : String,
      sha256 : String | null ? null,
      type : String ? "github",
    } -> {
      type : String,
      owner : String,
      repo : String,
      rev : String,
      sha256 : String | null,
      url : String,
    }
    ```

    # Example

    ```nix
    mkGitHubSource {
      owner = "nixos";
      repo = "nixpkgs";
      rev = "abc123...";
      sha256 = "sha256-...=";
    }
    # => { type = "github"; owner = "nixos"; repo = "nixpkgs"; rev = "abc123..."; sha256 = "sha256-...="; url = "https://github.com/nixos/nixpkgs/archive/abc123....tar.gz"; }
    ```
    */
    mkGitHubSource = {
      owner,
      repo,
      rev,
      sha256 ? null,
      type ? "github",
    }: {
      inherit type owner repo rev sha256;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    };

    /**
    Fetch a tarball from a source spec (as produced by `mkGitHubSource`).

    Reproducible when `sha256` is set: uses `fetchTarball { url; sha256; }`,
    which Nix can verify and cache without network access on a hash match.
    Falls back to an unpinned `fetchTarball url` when `sha256` is `null` or
    empty — convenient for local iteration, but not reproducible and always
    hits the network.

    # Inputs

    `src`
    : A source spec attrset with at least `url`, and optionally `sha256`.

    # Type

    ```
    fetchSource :: { url : String, sha256 : String | null, ... } -> Path
    ```

    # Example

    ```nix
    fetchSource (mkGitHubSource { owner = "nixos"; repo = "nixpkgs"; rev = "abc123..."; })
    ```
    */
    fetchSource = src:
      if src ? sha256 && src.sha256 != null && src.sha256 != ""
      then fetchTarball {inherit (src) url sha256;}
      else fetchTarball src.url;

    /**
    Resolve a NixOS module by name, preferring a live flake input over a
    pinned fallback source.

    Resolution order:
      1. If `enabled` is `false`, return `{}` (a valid, inert module).
      2. If `name` exists in `inputs`, use its `nixosModules.${name}` output,
         or the input itself if it has no such output (e.g. it *is* the
         module).
      3. Otherwise, fetch `sources.${name}` via `fetchSource` and either
         `import` it at `path`, or hand the fetched store path to `default`.

    Both `inputs` (live flake inputs) and `sources` (pinned fallbacks) are
    taken as explicit parameters rather than captured from enclosing scope,
    so this function stays pure and reusable outside this file.

    # Inputs

    `name`
    : Key into both `inputs` and `sources`. String.

    `path`
    : Subpath to `import` from the fetched source, relative to its root.
      Takes precedence over `default` when both could apply.
      Nullable string. Default `null`.

    `default`
    : Function applied to the fetched store path when `path` is not given.
      Nullable function `Path -> a`. Default `null`.

    `enabled`
    : Set `false` to skip resolution entirely and return `{}`. Bool.
      Default `true`.

    `inputs`
    : Live flake inputs to check first, keyed by name. Attrset. Default `{}`.

    `sources`
    : Pinned fallback fetch specs, keyed by name, as produced by
      `mkGitHubSource` (or an equivalent hand-built spec). Attrset.
      Default `{}`.

    # Type

    ```
    fetchModule :: {
      name : String,
      path : String | null ? null,
      default : (Path -> a) | null ? null,
      enabled : Bool ? true,
      inputs : AttrSet ? {},
      sources : AttrSet ? {},
    } -> AttrSet | a
    ```

    # Example

    ```nix
    fetchModule {
      name = "home-manager";
      path = "nixos";
      inherit inputs sources;
    }
    ```
    */
    fetchModule = {
      name,
      path ? null,
      default ? null,
      enabled ? true,
      inputs ? {},
      sources ? {},
    }:
      if !enabled
      then {} #? Returns an empty valid module!
      else if inputs ? ${name}
      then inputs.${name}.nixosModules.${name} or inputs.${name}
      else let
        fetched = fetchSource sources.${name};
      in
        if path != null
        then import "${fetched}/${path}"
        else default fetched;
  };

  schemas = let
    mkMergedList = {
      declared,
      requested,
    }: {
      inherit declared requested;
      resolved = unique (requested ++ declared);
    };

    mkMergedAttrs = {
      declared,
      requested,
    }: {
      inherit declared requested;
      #> Principal order is significant: earlier principals have priority.
      resolved =
        foldl'
        recursiveUpdate
        declared
        (reverseList requested);
    };

    deriveCapabilities = args: let
      names = attrNames args;
      unknown = builtins.filter (name: !(schema.user.capabilities ? ${name})) names;
      context = "deriveCapabilities";
    in
      assert requireThat {
        inherit context;
        condition = unknown == [];
        message = "unknown capabilities: ${toString unknown}";
      };
      args;

    mkCapabilities = {
      declared ? {},
      requested ? {},
    }: let
      requested' = deriveCapabilities requested;
    in {
      inherit declared;
      requested = requested';
      resolved =
        recursiveUpdate
        declared
        (mapAttrs
          (
            name: value:
              recursiveUpdate schema.user.capabilities.${name} value
          )
          requested');
    };

    mkHost = args: let
      derived = deriveHost args;
      context = "mkHost \"${toString derived.name}\"";

      defined = let
        principals =
          mkHostUsers context (derived.principals or []);

        desktops = mkMergedList {
          declared = derived.interface.desktops;
          requested = principals.interface.desktops;
        };

        fonts = {
          clock = mkMergedList {
            declared = derived.interface.fonts.clock;
            requested = principals.interface.fonts.clock;
          };
          emoji = mkMergedList {
            declared = derived.interface.fonts.emoji;
            requested = principals.interface.fonts.emoji;
          };
          material = mkMergedList {
            declared = derived.interface.fonts.material;
            requested = principals.interface.fonts.material;
          };
          monospace = mkMergedList {
            declared = derived.interface.fonts.monospace;
            requested = principals.interface.fonts.monospace;
          };
          sans = mkMergedList {
            declared = derived.interface.fonts.sans;
            requested = principals.interface.fonts.sans;
          };
          serif = mkMergedList {
            declared = derived.interface.fonts.serif;
            requested = principals.interface.fonts.serif;
          };
        };

        themes = mkMergedAttrs {
          declared = derived.interface.themes;
          requested = principals.interface.themes;
        };

        keyboard = mkMergedAttrs {
          declared = derived.interface.keyboard;
          requested = principals.interface.keyboard;
        };
      in {
        inherit derived principals;

        id =
          if isNotEmpty derived.id
          then derived.id
          else
            substring 0 8 (hashString "sha256" (toJSON {
              inherit (derived) name class description stateVersion;
            }));

        interface = {
          desktops = desktops.resolved;
          fonts = {
            clock = fonts.clock.resolved;
            emoji = fonts.emoji.resolved;
            material = fonts.material.resolved;
            monospace = fonts.monospace.resolved;
            sans = fonts.sans.resolved;
            serif = fonts.serif.resolved;
          };
          themes = themes.resolved;
          keyboard = keyboard.resolved;
        };

        __meta = {
          interface = {
            inherit desktops fonts themes keyboard;
          };
        };

        paths = let
          base = derived.paths.roots or {};
          roots = base // {run = base.run or (base.src or null);};
        in
          recursiveUpdate derived.paths {inherit roots;};
      };
    in
      recursiveUpdate derived defined;

    deriveFunctionalities = args: let
      names = unique args;
      unknown =
        builtins.filter
        (name: !(schema.host.functionalities ? ${name}))
        names;
      context = "deriveFunctionalities";
    in
      assert requireThat {
        inherit context;
        condition = unknown == [];
        message = "unknown functionalities: ${toString unknown}";
      };
      names;

    deriveHost = args: let
      raw =
        recursiveUpdate
        schema.host.defaults
        args;
      functionalities = deriveFunctionalities raw.functionalities;
      set = raw // {inherit functionalities;};
      name = raw.name or "<unnamed host>";
      context = "mkHost \"${toString name}\"";

      isSet = path: requireNonEmpty {inherit context path set;};
    in
      assert (requireThat {
        inherit context;
        condition =
          (isString set.id)
          && (isNotEmpty (match "^([0-9a-fA-F]{8})$" set.id));
        message = "id must be an 8-character hex string, got '${toString set.id}'";
      });
      assert (isSet ["paths" "roots" "src"]);
      assert (isSet ["stateVersion"]);
      assert (isSet ["system"]);
      assert (isSet ["name"]);
      #> Return the validated host
        set;
    derivePrincipal = args: let
      raw =
        recursiveUpdate
        schema.user.defaults
        args;
      name = raw.name or "<unnamed principal>";
      context = "mkPrincipal \"${toString name}\"";

      set = raw;
      isSet = path: requireNonEmpty {inherit context path set;};
    in
      assert (isSet ["name"]);
      assert (isSet ["role"]);
      assert (isSet ["hashedPassword"]);
      #> Return the validated principal
        set;

    mkPrincipal = args: let
      derived = derivePrincipal args;
      context = "mkPrincipal \"${toString derived.name}\"";
      requested = args;

      mkValue = {
        declared,
        requested ? null,
      }: {
        inherit declared requested;
        resolved =
          if requested == null
          then declared
          else requested;
      };

      defined = let
        name = mkValue {
          declared = derived.name;
          requested = if requested ? name then requested.name else null;
        };
        role = mkValue {
          declared = derived.role;
          requested = if requested ? role then requested.role else null;
        };
        description = mkValue {
          declared = "${toString derived.name} (${toString derived.role})";
          requested = if requested ? description then requested.description else null;
        };
        enable = mkValue {
          declared = derived.enable;
          requested = if requested ? enable then requested.enable else null;
        };
        autoLogin = mkValue {
          declared = derived.autoLogin;
          requested = if requested ? autoLogin then requested.autoLogin else null;
        };
        capabilities = mkCapabilities {
          requested = requested.capabilities or {};
        };
        localization = mkMergedAttrs {
          declared = derived.localization;
          requested = requested.localization or {};
        };
        identities = mkMergedList {
          declared = derived.identities;
          requested = requested.identities or [];
        };

        desktops = mkMergedList {
          declared = derived.interface.desktops;
          requested = requested.interface.desktops or [];
        };

        fonts = {
          clock = mkMergedList {
            declared = derived.interface.fonts.clock;
            requested = requested.interface.fonts.clock or [];
          };
          emoji = mkMergedList {
            declared = derived.interface.fonts.emoji;
            requested = requested.interface.fonts.emoji or [];
          };
          material = mkMergedList {
            declared = derived.interface.fonts.material;
            requested = requested.interface.fonts.material or [];
          };
          monospace = mkMergedList {
            declared = derived.interface.fonts.monospace;
            requested = requested.interface.fonts.monospace or [];
          };
          sans = mkMergedList {
            declared = derived.interface.fonts.sans;
            requested = requested.interface.fonts.sans or [];
          };
          serif = mkMergedList {
            declared = derived.interface.fonts.serif;
            requested = requested.interface.fonts.serif or [];
          };
        };

        themes = mkMergedAttrs {
          declared = derived.interface.themes;
          requested = requested.interface.themes or {};
        };

        keyboard = mkMergedAttrs {
          declared = derived.interface.keyboard;
          requested = requested.interface.keyboard or {};
        };

        paths = let
          requestedPaths = requested.paths or {};
          requestedRoots = requestedPaths.roots or {};
          declared = {
            roots.home = "/home/${toString derived.name}";
            stems = {};
          };
        in
          assert requireThat {
            inherit context;
            condition = !(requestedRoots ? src);
            message = "paths.roots.src is reserved for the host";
          };
          mkMergedAttrs {
            inherit declared;
            requested = requestedPaths;
          };

        packages = {
          shells = mkMergedList {
            declared = derived.packages.shells;
            requested = requested.packages.shells or [];
          };
          coding = mkMergedList {
            declared = derived.packages.coding;
            requested = requested.packages.coding or [];
          };
          common = mkMergedList {
            declared = derived.packages.common;
            requested = requested.packages.common or [];
          };
          launchers = mkMergedList {
            declared = derived.packages.launchers;
            requested = requested.packages.launchers or [];
          };
        };
      in {
        name = name.resolved;
        role = role.resolved;
        description = description.resolved;
        enable = enable.resolved;
        autoLogin = autoLogin.resolved;
        capabilities = capabilities.resolved;
        identities = identities.resolved;
        localization = localization.resolved;

        interface = {
          desktops = desktops.resolved;
          fonts = {
            clock = fonts.clock.resolved;
            emoji = fonts.emoji.resolved;
            material = fonts.material.resolved;
            monospace = fonts.monospace.resolved;
            sans = fonts.sans.resolved;
            serif = fonts.serif.resolved;
          };
          themes = themes.resolved;
          keyboard = keyboard.resolved;
        };

        inherit paths;

        packages = {
          shells = packages.shells.resolved;
          coding = packages.coding.resolved;
          common = packages.common.resolved;
          launchers = packages.launchers.resolved;
        };

        __meta = {
          inherit name role description enable autoLogin capabilities identities localization;
          interface = {
            inherit desktops fonts themes keyboard;
          };
          inherit paths packages;
        };
      };
    in
      recursiveUpdate derived defined;
    mkHostUsers = context: args: let
      principals = map mkPrincipal args;
      hasAdmin = any (principal: principal.role == "administrator") principals;
      total = length principals;
      primary = head principals;
      secondary =
        if total > 1
        then elemAt principals 1
        else null;
      tertiary =
        if total > 2
        then elemAt principals 2
        else null;
      others = optionals (total > 3) (tail (tail (tail principals)));
      names = map (user: user.name) principals;
      interface = {
        desktops = unique (concatMap (user: user.interface.desktops or []) principals);
        fonts = {
          clock = unique (concatMap (user: user.interface.fonts.clock or []) principals);
          emoji = unique (concatMap (user: user.interface.fonts.emoji or []) principals);
          material = unique (concatMap (user: user.interface.fonts.material or []) principals);
          monospace = unique (concatMap (user: user.interface.fonts.monospace or []) principals);
          sans = unique (concatMap (user: user.interface.fonts.sans or []) principals);
          serif = unique (concatMap (user: user.interface.fonts.serif or []) principals);
        };
        themes = map (user: user.interface.themes or {}) principals;
        keyboard = map (user: user.interface.keyboard or {}) principals;
      };
      count = total;
    in
      assert requireThat {
        inherit context;
        message = "principals list must not be empty";
        condition = isNotEmpty principals;
      };
      assert requireThat {
        inherit context;
        message = "at least one principal must have role \"administrator\" (got: ${toString names})";
        condition = hasAdmin;
      }; {
        all = principals;
        inherit primary secondary tertiary others names count interface;
      };
  in {inherit deriveCapabilities deriveFunctionalities deriveHost derivePrincipal mkHost mkHostUsers mkCapabilities mkPrincipal;};

  strings = {
    inherit (builtins) hashString;

    #> Render a dotted path list as a string, e.g. ["paths" "roots" "src"] -> "paths.roots.src"
    showPath = path: concatStringsSep "." path;

    /**
    Upper-case the first character of a string, leaving the rest unchanged.

    # Inputs

    `text`
    : String to capitalize. Must be non-empty (an empty string will error,
      since `substring 0 1 ""` is `""` and `toUpper ""` is fine, but callers
      relying on a non-empty result should check first).

    # Type

    ```
    capitalize :: String -> String
    ```

    # Example

    ```nix
    capitalize "nixos"  # => "Nixos"
    capitalize "Nix"    # => "Nix"
    ```
    */
    capitalize = text:
      toUpper (substring 0 1 text) + substring 1 (-1) text;
  };

  trivial = {
    /**
    Whether a value is "empty": `null`, an empty/whitespace-only string, an
    empty list, or an empty attrset. Any other value (including `0`,
    `false`) is not considered empty.

    # Inputs

    `value`
    : The value to check. Any type.

    # Type

    ```
    isEmpty :: a -> Bool
    ```

    # Example

    ```nix
    isEmpty null       # => true
    isEmpty "   "      # => true
    isEmpty []         # => true
    isEmpty {}         # => true
    isEmpty "hi"       # => false
    isEmpty 0          # => false
    ```
    */
    isEmpty = value:
      if (value == null)
      then true
      else if isString value
      then ((value == "") || ((stringLength (trim value)) == 0))
      else if isList value
      then value == []
      else if isAttrs value
      then value == {}
      else false;

    /**
    Negation of `isEmpty`.

    # Inputs

    `value`
    : The value to check. Any type.

    # Type

    ```
    isNotEmpty :: a -> Bool
    ```

    # Example

    ```nix
    isNotEmpty "hi"  # => true
    isNotEmpty []    # => false
    ```
    */
    isNotEmpty = value: !isEmpty value;
  };
in
  recursiveUpdate lib
  {inherit debug fetchers schema strings trivial schemas;}
