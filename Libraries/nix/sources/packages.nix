{_, ...}: let
  meta = {
    doc = ''
      Input Packages Resolution

      Builds the complete package sets and Nixpkgs instances from resolved inputs.
      It threads configurations and generated overlays into a finalized `nixpkgs`
      attribute set ready for system evaluation.
    '';

    exports = {
      internal = let
        functions = {
          inherit
            fromInputs
            getVersion
            mkAll
            mkCore
            mkHome
            mkOne
            pkgOf
            pkgsFrom
            ;
        };
        aliases = {
          mkPkgs = mkAll;
          mkPackages = mkAll;
          mkPackage = mkOne;
          mkPackageFromInputs = fromInputs;
          mkCorePackages = mkCore;
          mkHomePackages = mkHome;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        mkInputOverlays = mkOverlays;
        mkInputPackages = mkAll;
        mkPackageFromInputs = fromInputs;
        mkInputPackage = mkOne;
        mkCoreInputPackages = mkCore;
        mkHomeInputPackages = mkHome;
      };
    };
  };

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getFlake;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.hardware.system) getSystemOrDefault;
  inherit (_.lists.access) findFirst head;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.construction) asList optionals;
  inherit (_.lists.selection) filter;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.access) match;
  inherit (_.strings.construction) concat;
  inherit (_.strings.predicates) hasPrefix hasSuffix isString;
  inherit (_.strings.transformation) removePrefix removeSuffix;
  inherit (_.sources.access) getBin getExe getExe';
  inherit (_.sources.inputs) normalize mkSource;
  inherit (_.sources.overlays) mkOverlays;

  defaults = {
    config = {
      allowUnfree = true;
      allowBroken = false;
    };
    core = {
      attrs = "legacyPackages";
      names = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
    };
    home = {
      attrs = "packages";
      names = [
        "age"
        "caelestia"
        "catppuccin"
        "dank-material-shell"
        "dms-plugin-registry"
        "fresh-editor"
        "helix"
        "hermes-agent"
        "home-manager"
        "llm-agents"
        "noctalia-shell"
        "nvf"
        "plasma"
        "quickshell"
        "treefmt"
        "typix"
        "vscode-insiders"
        "zen-browser"
      ];
    };
  };

  mkCore = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      inherit inputs;
      inherit (defaults.core) attrs;
      names = defaults.core.names ++ names;
    };

  mkHome = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      inherit (defaults.home) attrs;
      inherit inputs;
      names = defaults.home.names ++ names;
    };

  fromInputs = {
    inputs,
    system,
    input,
  }: let
    packages = inputs.${input}.packages.${system} or {};
    formatter = inputs.${input}.formatter.${system} or null;
  in
    if packages != {}
    then packages
    else if formatter != null
    then {${input} = formatter;}
    else {};

  /**
    Build the final version string for a resolved package: derives a
    static version from `package.version`/`pname` parsing, falls back to
    a shell probe against `exe` if that's unavailable, and combines
    whichever succeeds with `revision`.

    Derivation, tried in order:
      1.`package.version`, if set and non-empty
      2.the leading dotted-number sequence in `pname` (with the `pname-`
        prefix stripped from `name` first, if both are set) or bare `name`
        otherwise, tolerating an optional leading `v`/`V`

    If neither yields a value, and `args` is non-empty, falls back to a
    shell probe: runs `exe` with `args` (string or list, normalized via
    `asList`) plus `extra` trailing text, discards stderr, and greps the
    first dotted-number sequence out of stdout. The probe is only ever
    embedded as a `$(...)` shell substitution in the returned string,
    never executed at eval time.

    Final combination, in priority order:
      1. derived + `revision`  -> "`derived` (`revision`)"
      2. derived alone         -> "`derived`"
      3. probe + `revision`    -> "$(probe) (`revision`)"
      4. `revision` alone      -> "`revision`"
      5. probe alone           -> "$(probe)"
      6. nothing resolved      -> `null`

    # Inputs
    `package`
    : the resolved derivation to inspect

    `revision`
    : git short-rev/rev string, or `null` if unavailable

    `exe`
    : path to the executable to probe, used only if derivation fails and
      `args` is non-empty

    `args`
    : version flag(s) to pass, e.g. `"--version"` or `["-V"]`; normalized
      via `asList`; empty/`null` disables the probe entirely

    `extra`
    : additional trailing shell text appended after `args`; default `""`

    # Type
    ```nix
    getVersion :: { package :: derivation, revision :: string?, exe :: string, args :: string | [string] | null, extra :: string? } -> string | null
    ```

    # Examples
    ```nix
    getVersion { package = pkgs.ripgrep; revision = null; exe = "..."; args = null; }
    ```
    ```sh
    "14.1.0"
    ```

    - getVersion { package = someFlakeOutputWithNoVersion; revision = "ae79109"; exe = "/nix/store/.../bin/treefmt"; args = "--version"; }
    > "$(/nix/store/.../bin/treefmt --version  2>/dev/null | grep -oE '[0-9]+(\\.[0-9]+)+' | head -n1) (ae79109)"

    - getVersion { package = someFlakeOutputWithNoVersion; revision = null; exe = "..."; args = null; }
  null
  */
  getVersion = {
    package,
    revision ? null,
    exe,
    args ? null,
    extra ? "",
  }: let
    derived = let
      raw = package.version or null;
      fromName = let
        name = package.pname or package.name or "";
        pname = package.pname or null;
        stripped =
          if pname != null && hasPrefix "${pname}-" name
          then removePrefix "${pname}-" name
          else name;
        matches = match "[vV]?([0-9]+([.][0-9]+)*).*" stripped;
      in
        if matches != null
        then head matches
        else null;
    in
      if raw != null && raw != ""
      then raw
      else fromName;

    #> One flag-set per attempt. Explicit `args` -> exactly one attempt.
    #> `null` -> try each of the default flags in turn. `false`/`[]` -> no probe.
    flagCandidates =
      if args == false || args == []
      then []
      else if args != null
      then [(asList args)]
      else
        map (flag: [flag]) [
          "--version"
          "-V"
          "version"
        ];

    probe =
      if derived == null && flagCandidates != []
      then let
        attempts = map (flags: "${exe} ${concat " " flags} ${extra} 2>/dev/null") flagCandidates;
        joined = concat " || " attempts;
      in "{ ${joined}; } | grep -oE '[0-9]+(\\.[0-9]+)+' | head -n1"
      else null;
  in
    findFirst (candidate: candidate != null) null [
      (
        if derived != null && revision != null
        then "${derived} (${revision})"
        else null
      )
      (
        if derived != null
        then derived
        else null
      )
      (
        if revision != null && probe != null
        then "$(${probe}) (${revision})"
        else null
      )
      (
        if revision != null
        then revision
        else null
      )
      (
        if probe != null
        then "$(${probe})"
        else null
      )
    ];

  # -- pkgOf

  /**
  Resolve a single package by name, trying `input`'s flake package set
  first, then `pkgs`.

  Either `pkgs` or `system` must resolve to a real value: if `pkgs` is
  given, `system` defaults to `pkgs.stdenv.hostPlatform.system`; otherwise
  `system` must be supplied explicitly. Throws if neither is available.

  Candidate names are tried against both sources, in order:
  1. the explicit `target`, if given;
  2. `"default"` (the flake's own default package output);
  3. best-effort suffix-stripped variants of `input` (e.g.
    `"treefmt-nix"` -> `"treefmt"`, via the `-nix`/`.nix`/`-flake`
    suffixes), since an input's name and its package's attribute name
    frequently differ and can't be inferred with certainty - a hit here
    is a guess, not a guarantee, so double-check the resolved package
    if `target` was left unset and the result looks unexpected.

  The returned `name` reflects whichever candidate actually resolved
  (e.g. `"treefmt"`, not the `input` string `"treefmt-nix"`), not
  necessarily `target` itself.

  Pass `target` explicitly whenever the package's real attribute name is
  known and doesn't match `input` or `"default"` - this both guarantees
  the correct package and skips the guesswork.

  When `required` is true, throws if no candidate resolves in either
  source, listing every name that was tried. Otherwise returns `null` on
  a full miss.

  # Inputs
  `inputs`
  : the flake's own `inputs` attrset, used to resolve `input`'s flake
    outputs

  `input`
  : name of the flake input to look up the package under, e.g.
    `"treefmt-nix"`

  `target`
  : explicit attribute name to resolve, tried before `"default"` and the
    suffix-stripped guesses; default `null` (skip straight to guessing)

  `exe`
  : optional binary name within the resolved package to expose as `.exe`
    via `getExe'`; when omitted, `.exe` is `getExe value` (the package's
    own main binary)

  `pkgs`
  : an already-instantiated `pkgs` to fall back to and to derive `system`
    from; default `null` (falls back to importing `inputs.nixpkgs`
    directly using `system`)

  `system`
  : target system string, default `pkgs.stdenv.hostPlatform.system` when
    `pkgs` is given, otherwise must be supplied

  `required`
  : whether a full miss throws (`true`) or returns `null` (`false`),
    default `false`

  # Type
  > pkgOf :: { inputs :: AttrSet, input :: string, target :: string?, exe :: string?, pkgs :: AttrSet?, system :: string?, required :: bool? } -> { name :: string, value :: derivation, pkg :: derivation, exe :: string, paths :: { bin :: path, store :: path } } | null

  # Examples
  > pkgOf { inherit `inputs` `pkgs`; `input` = _"treefmt-nix"_; `target` = _"treefmt"_; }

  ```nix
  {
    name = "treefmt";
    value = «derivation treefmt-2.x.x»;
    pkg = «derivation treefmt-2.x.x»;
    exe = "/nix/store/.../bin/treefmt";
    paths = {...};
  }
  ```

  > pkgOf { inherit `inputs` `pkgs`; `input` = _"treefmt-nix"_; }

    ```nix
    { name = "treefmt"; value = «derivation treefmt-2.x.x»; ... }
    ```
    - (no `target` given - neither `"default"` nor `"treefmt-nix"` itself
    matched, but the `-nix` suffix-strip guess `"treefmt"` did, and `name`
    correctly reports that real match rather than the `input` string)

  > pkgOf { inherit inputs pkgs; input = "not-a-real-input"; required = true; }

    ```nix
    error: Unable to locate a package for input 'not-a-real-input' - tried: default, not-a-real-input. Pass `target` explicitly to pkgFor/pkgOf.
    ```
  */
  pkgOf = {
    inputs ? {},
    input ? null,
    target ? null,
    exe ? null,
    pkgs ? null,
    description ? null,
    system ?
      if pkgs != null
      then pkgs.stdenv.hostPlatform.system
      else null,
    required ? false,
    versionArgs ? null,
  }: let
    _name = "pkgOf";

    init = {
      inherit inputs input pkgs;

      system = assert withContext {
        name = _name;
        context = "resolving system for package from input '${input}' or pkgs";
        assertion = system != null;
        message = "either `pkgs` or `system` must be provided.";
      }; system;

      source = {
        legacy =
          if pkgs != null
          then pkgs
          else import init.inputs.nixpkgs {inherit (init) system;};
        flakes = optionalAttrs (input != null) (fromInputs {
          inherit (init) inputs input system;
        });
      };
    };

    #> Names to try, in order:
    #> 1. the explicitly given `target`, if provided
    #> 2. "default" (the flake's own default package output)
    #> 3. best-effort suffix-stripped variants of `input`
    #>    (e.g. "treefmt-nix" -> "treefmt"), since an input's name
    #>    and its package's attribute name frequently differ and
    #>    can't be inferred reliably - these are guesses, not
    #>    guarantees, so a hit here should be spot-checked if the
    #>    resolved package looks unexpected
    suffixStripped =
      if input == null
      then []
      else let
        suffixes = [
          "-nix"
          ".nix"
          "-flake"
        ];
        strip = suffix:
          if hasSuffix suffix input
          then removeSuffix suffix input
          else null;
        stripped = filter (name: name != null) (map strip suffixes);
      in
        unique stripped;

    candidateNames =
      if target != null
      then [target]
      else
        unique (
          (optionals (input != null) ["default"])
          ++ suffixStripped ++ (optionals (input != null) [input])
        );

    lookup = candidates: let
      findMatch = name: let
        src = init.source;
        flake = src.flakes.${name} or null;
        legacy = src.legacy.${name} or null;
      in
        if flake != null
        then {
          inherit name;
          value = flake;
          source =
            if input != null
            then input
            else "input";
        }
        else if legacy != null
        then {
          inherit name;
          value = legacy;
          source = "nixpkgs";
        }
        else null;
    in
      findFirst (candidate: candidate != null) null (map findMatch candidates);
    check = lookup candidateNames;

    eval =
      if check == null || check.value == null
      then null
      else let
        package = check.value;

        paths = {
          executable =
            if exe != null
            then getExe' package exe
            else getExe package;
          binary = "${getBin package}/bin";
          store = package.outPath or "${package}";
        };

        command = baseNameOf paths.executable;

        fromInput = check.source != "nixpkgs";

        revision =
          if fromInput && input != null
          then let
            flake = init.inputs.${input};
          in
            flake.shortRev or (flake.rev or null)
          else null;

        version = getVersion {
          inherit package revision;
          exe = paths.executable;
          args = versionArgs;
        };

        description =
          if description != null && description != ""
          then description
          else package.meta.description or null;
      in {
        inherit (check) name source value;
        inherit
          command
          description
          package
          paths
          revision
          version
          ;

        bin = paths.binary;
        cmd = command;
        exe = paths.executable;
        pkg = package;
        vr3n = version;
        ver = version;
      };
  in
    if required
    then
      assert withContext {
        name = _name;
        context = "resolving package from input '${toString input}' or pkgs";
        assertion = eval != null;
        message = "Unable to locate a package for input '${toString input}' - tried: ${concat ", " candidateNames}. Pass `target` explicitly to pkgFor/pkgOf.";
      }; eval
    else eval;

  # -- pkgsFrom

  /**
    Resolve multiple named packages via `pkgOf`, one input per name.

    `sources` maps package name -> input name, e.g.
    `{codex = "llm-agents"; "hermes-agent" = "llm-agents";}` - this lets
    ambiguous names (present in more than one input) resolve to a specific
    input per-package, rather than relying on a single global priority
    order. Each package's own name is passed to `pkgOf` as `target`, so it
    resolves exactly that attribute rather than falling back to `"default"`
    or a suffix-stripped guess.

    Returns the resolved attrset (name -> `pkgOf` result) merged with three
    convenience keys:
      - `names`    - `attrNames` of the resolved set
      - `values`   - `attrValues` of the resolved set (the full `pkgOf`
                      result records, `{name; value; pkg; exe; paths;}`)
      - `packages` -  just the derivations (`value` from each record),
                      ready to splice into a flat `packages = [...] ++ ...`
                      list

    `system` is passed straight through to `pkgOf` only when explicitly
    given; when omitted, each `pkgOf` call derives it from `pkgs` itself,
    so passing an explicit `null` here can't shadow that derivation.

    # Inputs
    `inputs`
    : the flake's own `inputs` attrset, threaded through to every `pkgOf`
      call

    `sources`
    : attrset of package name -> input name, e.g.
      `{treefmt = "treefmt-nix";}`

    `pkgs`
    : an already-instantiated `pkgs`, threaded through to every `pkgOf`
      call; default `null`

    `system`
    : target system string, threaded through to every `pkgOf` call only
      when non-`null`; default `null`

    `required`
    : whether a miss on any individual package throws (`true`, via
      `pkgOf`'s own `required`) or is silently dropped from the result
      (`false`); default `false`

    # Type
    > pkgsFrom :: { inputs :: AttrSet, sources :: AttrSet, pkgs :: AttrSet?, system :: string?, required :: bool? } -> AttrSet

    # Examples
    - pkgsFrom { inherit inputs pkgs; sources = { treefmt = "treefmt-nix"; }; }

  ```nix
    { treefmt = {name = "treefmt"; value = «derivation»; ...}; names = ["treefmt"]; values = [{...}]; packages = [«derivation»]; }
  ```

    - pkgsFrom {
        inherit inputs pkgs;
        sources = {
          codex = "llm-agents";
          hermes-agent = "llm-agents";
          openclaw = "llm-agents";
          opencode = "llm-agents";
        };
      }

  ```nix
    { codex = {...}; hermes-agent = {...}; openclaw = {...}; opencode = {...}; names = [...]; values = [...]; packages = [«codex» «hermes-agent» «openclaw» «opencode»]; }
  ```
    (four package names, all resolved from the same `llm-agents` input -
    `sources` repeats the input string per name since there's no
    same-input shortcut)
  */
  pkgsFrom = {
    inputs,
    sources,
    pkgs ? null,
    system ? null,
    required ? false,
    exclude ? [],
    aliases ? {},
  }: let
    init = let
      normalize = value:
        if value == null
        then {
          input = null;
          versionArgs = null;
          description = null;
        }
        else if isString value
        then {
          input = value;
          versionArgs = null;
          description = null;
        }
        else {
          input = value.input or null;
          versionArgs = value.versionArgs or null;
          description = value.description or null;
        };

      source = target: entry:
        pkgOf (
          {
            inherit target inputs pkgs required;
            inherit (entry) input versionArgs description;
          }
          // optionalAttrs (system != null) {inherit system;}
        );
    in
      filterAttrs (_: src: src != null) (
        mapAttrs
        (name: entry: source name entry)
        (mapAttrs (_: normalize) sources)
      );

    byName =
      init
      // filterAttrs
      (_: v: v != null)
      (mapAttrs (_: target: init.${target} or null) aliases);

    eval = {
      binaries = mapAttrs (_: pkg: pkg.exe) byName;
      commands = mapAttrs (_: pkg: pkg.cmd) byName;
      versions = mapAttrs (_: pkg: pkg.ver) byName;
      origins = mapAttrs (_: pkg: pkg.source) byName;
      descriptions = mapAttrs (_: pkg: pkg.description or null) byName;
      packages = filter (pkg: !(elem (pkg.pname or pkg.name or "") exclude)) (
        map (res: res.value) (attrValues init)
      );
      names = attrNames byName;
    };

    aliases' = with eval; {
      bins = binaries;
      cmds = commands;
      vr3n = versions;
    };
  in
    byName
    // eval
    // aliases'
    // {
      inherit sources;
      records = byName;
    };

  bySystem = packages: let
    inputNames = attrNames packages;
    systems = unique (concatMap (name: attrNames (packages.${name} or {})) inputNames);
    inputsFor = system: filter (name: hasAttr system (packages.${name} or {})) inputNames;
  in
    listToAttrs (
      map (system: {
        name = system;
        value = listToAttrs (
          map (name: {
            inherit name;
            value = packages.${name}.${system};
          }) (inputsFor system)
        );
      })
      systems
    );

  mkOne = {
    inputs,
    attrs,
    names,
  }:
    listToAttrs (
      map (name: {
        inherit name;
        value = inputs.${name}.${attrs} or {};
      })
      names
    );

  mkAll = {
    flake ? {},
    host ? {},
    inputs ? {},
    # nixpkgs ? {},
    system ? null,
    config ? {},
    coreNames ? [],
    homeNames ? [],
  }: let
    inputs' = normalize (
      if isNotEmpty inputs
      then inputs
      else if isNotEmpty flake
      then flake
      else getFlake {}
    );

    system' = getSystemOrDefault {
      inputs = inputs';
      inherit host system;
    };

    config' = let
      pkgs = host.packages or {};
    in
      {
        allowUnfree = pkgs.allowUnfree or (defaults.allowUnfree or false);
        allowBroken = pkgs.allowBroken or (defaults.allowBroken or false);
      }
      // config;

    packages = let
      raw =
        mkCore {
          inputs = inputs';
          names = coreNames;
        }
        // mkHome {
          inputs = inputs';
          names = homeNames;
        };
    in
      filterAttrs (_name: isNotEmpty) raw;

    overlays = mkOverlays {
      inherit packages;
      inputs = inputs';
      config = config';
    };

    nixpkgs' = let
      source = let
        src = mkSource {
          inherit host;
          input = inputs'.nixpkgs or null;
        };
      in
        optionalAttrs (isNotEmpty src) (src.flake.source or src.source);
    in
      source
      // {
        inputs = inputs';
        legacyPackages = mapAttrs (sys: base: base // ((bySystem packages).${sys} or {})) (
          inputs'.nixpkgs.legacyPackages or {}
        );
      };
  in {
    inherit packages overlays;

    inputs = inputs';
    config = config';
    nixpkgs = nixpkgs';

    pkgs = import inputs'.nixpkgs {
      inherit overlays;
      system = system';
      config = config';
    };
  };
in
  with meta.exports;
    internal
    // {
      __docs = meta.doc;
      __rootAliases = external;
    }
