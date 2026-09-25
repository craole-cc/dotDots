{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) attrByPath isAttrs recursiveUpdate;
  inherit (lib.lists) any concatMap elemAt head isList length optionals tail unique;
  inherit (lib.strings) concatStringsSep isString match stringLength substring toUpper toJSON trim;
  inherit (fetchers) fetchSource;
  inherit (strings) hashString showPath;
  inherit (trivial) isEmpty isNotEmpty;
  inherit (debug) requireNonEmpty requireThat;

  debug = {
    #> Assert that `set` has a non-empty value at `path`. On failure, throw a message
    #> naming the missing/empty field and the surrounding context (host/principal name),
    #> instead of Nix's opaque "attribute missing" trace.
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
    empty -- convenient for local iteration, but not reproducible and always
    hits the network.

    # Type

    ```
    fetchSource :: { url : String, sha256 : String | null, ... } -> Path
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

  defaults = {
    host = {
      stateVersion = "";
      system = "";
      class = "nixos";
      name = "";
      id = null; #> null => auto-derive an 8-char hash from name/class/description/stateVersion
      description = null;
      functionalities = [];
      localization = {
        latitude = 18.015;
        longitude = -77.49;
        city = "Mandeville, Jamaica";
        timeZone = "America/Jamaica";
        defaultLocale = "en_US.UTF-8";
      };
      interface = {
        boot = {
          loader = {
            manager = "systemd-boot";
            device = "nodev";
            timeout = 5;
          };
        };
        desktops = [];
      };
      paths = {};
      specs = {};
      packages = {};
      principals = [];
    };
    user = {
      name = null;
      role = null;
      description = null;
      password = null;
      hashedPassword = null;
      enable = true;
      autoLogin = false;
      capabilities = [];
      localization = {};
      identities = [];
      desktops = [];
      interface = {
        keyboard = {
          layout = "us";
          variant = "";
          swapCapsEscape = false;
          vimKeybinds = false;
          bindings.modifier = ["SUPER"];
        };
      };
      paths = {};
      packages = {};
    };
  };

  schemas = let
    mkHost = args: let
      defined = recursiveUpdate defaults.host args;
      name = defined.name or "<unnamed host>";
      context = "mkHost \"${toString name}\"";

      id =
        if isNotEmpty defined.id
        then defined.id
        else
          substring 0 8 (hashString "sha256" (toJSON {
            inherit (defined) name class description stateVersion;
          }));

      principals = mkHostUsers context (defined.principals or []);

      paths = let
        base = defined.paths.roots or {};
        roots = base // {run = base.run or (base.src or null);};
      in
        recursiveUpdate defined.paths {inherit roots;};

      #> Every desktop a principal needs must end up available on the
      #> host, without declaring it twice. `common` keeps the
      #> declared/requested/resolved breakdown visible for debugging;
      #> `interface.desktops` carries the resolved list, since that's
      #> what NixOS options actually read.
      common = {
        desktops = {
          declared = defined.interface.desktops;
          requested = principals.desktops;
          resolved = unique (defined.interface.desktops ++ principals.desktops);
        };
      };

      interface = recursiveUpdate defined.interface {desktops = common.desktops.resolved;};

      resolved = defined // {inherit id principals paths interface common;};
      forMissing = path:
        requireNonEmpty {
          inherit context path;
          set = resolved;
        };
    in
      assert requireThat {
        inherit context;
        condition =
          (isString resolved.id)
          && (isNotEmpty (match "^([0-9a-fA-F]{8})$" resolved.id));
        message = "id must be an 8-character hex string, got '${toString resolved.id}'";
      };
      assert forMissing ["paths" "roots" "src"];
      assert forMissing ["stateVersion"];
      assert forMissing ["system"];
      assert forMissing ["name"];
      #> Return the validated host
        resolved;

    mkPrincipal = args: let
      defined = recursiveUpdate defaults.user args;
      context = "mkPrincipal \"${toString (defined.name or "<unnamed>")}\"";

      description =
        if defined.description != null && defined.description != ""
        then defined.description
        else "${toString defined.name} (${toString defined.role})";

      #> Sane default: derive $HOME from the name if not explicitly set.
      home =
        if (defined.paths.home or null) != null
        then defined.paths.home
        else "/home/${toString defined.name}";

      paths = recursiveUpdate defined.paths {inherit home;};

      resolved = defined // {inherit description paths;};
    in
      assert requireNonEmpty {
        inherit context;
        path = ["name"];
        set = resolved;
      };
      assert requireNonEmpty {
        inherit context;
        path = ["role"];
        set = resolved;
      };
      assert requireNonEmpty {
        inherit context;
        path = ["hashedPassword"];
        set = resolved;
      }; resolved;

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
      names = map (principal: principal.name) principals;
      desktops = unique (concatMap (p: p.desktops) principals);
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
        inherit primary secondary tertiary others names count desktops;
      };
  in {inherit defaults mkHost mkPrincipal;};

  strings = {
    inherit (builtins) hashString;

    #> Render a dotted path list as a string, e.g. ["paths" "roots" "src"] -> "paths.roots.src"
    showPath = path: concatStringsSep "." path;

    /**
    Upper-case the first character of a string, leaving the rest unchanged.

    # Type

    ```
    capitalize :: String -> String
    ```

    # Example

    ```nix
    capitalize "nixos"  # => "Nixos"
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

    # Type

    ```
    isEmpty :: a -> Bool
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

    # Type

    ```
    isNotEmpty :: a -> Bool
    ```
    */
    isNotEmpty = value: !isEmpty value;
  };
in
  recursiveUpdate lib
  {inherit debug fetchers strings trivial schemas;}
