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
            mkCore
            mkHome
            mkAll
            mkOne
            fromInputs
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
  inherit (_.lists.access) head;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.construction) optionals;
  inherit (_.lists.selection) filter;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.access) match;
  inherit (_.strings.construction) concat;
  inherit (_.strings.predicates) hasPrefix hasSuffix;
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
    - pkgOf { inherit inputs pkgs; input = "treefmt-nix"; target = "treefmt"; }

  ```nix
    { name = "treefmt"; value = «derivation treefmt-2.x.x»; pkg = «derivation treefmt-2.x.x»; exe = "/nix/store/.../bin/treefmt"; paths = {...}; }
  ```

    - pkgOf { inherit inputs pkgs; input = "treefmt-nix"; }

  ```nix
    { name = "treefmt"; value = «derivation treefmt-2.x.x»; ... }
  ```
    (no `target` given - neither `"default"` nor `"treefmt-nix"` itself
    matched, but the `-nix` suffix-strip guess `"treefmt"` did, and `name`
    correctly reports that real match rather than the `input` string)

    - pkgOf { inherit inputs pkgs; input = "not-a-real-input"; required = true; }

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
    system ?
      if pkgs != null
      then pkgs.stdenv.hostPlatform.system
      else null,
    required ? false,
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
          else
            import init.inputs.nixpkgs
            {inherit (init) system;};
        flakes =
          optionalAttrs
          (input != null)
          (fromInputs {inherit (init) inputs input system;});
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
        suffixes = ["-nix" ".nix" "-flake"];
        strip = suffix:
          if hasSuffix suffix input
          then removeSuffix suffix input
          else null;
        stripped = filter (n: n != null) (map strip suffixes);
      in
        unique stripped;

    candidateNames = unique (
      (optionals (target != null) [target])
      ++ (optionals (input != null) ["default"])
      ++ suffixStripped
      ++ (optionals (input != null) [input])
    );

    lookup = candidates:
      foldl'
      (found: name:
        if found != null
        then found
        else let
          flake = init.source.flakes.${name} or null;
          legacy = init.source.legacy.${name} or null;
        in
          if flake != null
          then {
            inherit name;
            source = "input";
            value = flake;
          }
          else if legacy != null
          then {
            inherit name;
            source = "nixpkgs";
            value = legacy;
          }
          else null)
      null
      candidates;

    check = lookup candidateNames;

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
    version = let
      raw = package.version or null;
      # e.g. "treefmt-2.5.0" or "treefmt-2.5.0-env"
      fromName = let
        n = package.pname or package.name or "";
        # strip pname prefix if present
        pname = package.pname or null;
        stripped =
          if pname != null && hasPrefix "${pname}-" n
          then removePrefix "${pname}-" n
          else n;
        m = match "([0-9]+([.][0-9]+)*).*" stripped;
      in
        if m != null
        then head m
        else null;
    in
      if raw != null && raw != ""
      then raw
      else fromName;
    revision =
      if check.source == "input"
      then let
        name = init.inputs.${input};
      in
        name.shortRev or name.rev or null
      else null;
    vr3n =
      if version != null && revision != null
      then "${version} (${revision})"
      else if version != null
      then version
      else if revision != null
      then revision
      else null;

    eval =
      if check == null || check.value == null
      then null
      else {
        inherit (check) name source value;
        inherit package paths command revision vr3n version;

        bin = paths.binary;
        cmd = command;
        exe = paths.executable;
        pkg = package;
        ver = vr3n;
      };
  in
    if required
    then
      assert withContext {
        name = _name;
        context = "resolving package from input '${toString input}' or pkgs";
        assertion = eval != null;
        message = "Unable to locate a package for input '${toString input}' - tried: ${
          concat ", " candidateNames
        }. Pass `target` explicitly to pkgFor/pkgOf.";
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
    source = target: input:
      pkgOf (
        {
          inherit target inputs pkgs required;
          input =
            if input == null
            then null
            else input;
        }
        // optionalAttrs (system != null) {inherit system;}
      );

    init =
      filterAttrs (_: v: v != null)
      (mapAttrs (name: input: source name input) sources);

    aliased = filterAttrs (_: v: v != null) (
      mapAttrs (_: target: init.${target} or null) aliases
    );

    byName = init // aliased;

    eval = {
      binaries = mapAttrs (_: v: v.exe) byName;
      commands = mapAttrs (_: v: v.cmd) byName;
      versions = mapAttrs (_: v: v.ver) byName;
      packages =
        filter
        (pkg: !(elem (pkg.pname or pkg.name or "") exclude))
        (map (v: v.value) (attrValues init)); # unique derivations only
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

    systems = unique (
      concatMap
      (name: attrNames (packages.${name} or {}))
      inputNames
    );

    inputsFor = system:
      filter
      (name: hasAttr system (packages.${name} or {}))
      inputNames;
  in
    listToAttrs (
      map (system: {
        name = system;
        value = listToAttrs (
          map (name: {
            inherit name;
            value = packages.${name}.${system};
          })
          (inputsFor system)
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
        legacyPackages =
          mapAttrs
          (sys: base: base // ((bySystem packages).${sys} or {}))
          (inputs'.nixpkgs.legacyPackages or {});
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
