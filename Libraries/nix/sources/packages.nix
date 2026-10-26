{
  _,
  _default,
  ...
}: let
  meta = {
    doc = ''
      Input Packages Resolution

      Builds the complete package sets and Nixpkgs instances from resolved inputs.
      It threads configurations and generated overlays into a finalized `nixpkgs`
      attribute set ready for system evaluation.
    '';

    exports = {
      internal = let
        functions = {inherit fromInputs getVersion mkAll mkCore mkHome mkOne pkgOf pkgsFrom mkToolkit;};
        aliases = {
          mkPkgs = mkAll;
          mkPackages = mkAll;
          mkPackage = mkOne;
          mkPackageFromInputs = fromInputs;
          mkCorePackages = mkCore;
          mkHomePackages = mkHome;
          mkCommonPackages = mkToolkit;
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
  inherit (_.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (_.attrsets.construction) genAttrs nameValuePair listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs mapAttrs';
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.access) readDir;
  inherit (_.hardware.system) getSystemOrDefault;
  inherit (_.lists.access) findFirst head;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.construction) asList optionals;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.sources.access) getBin getExe';
  inherit (_.sources.inputs) normalizeInputs mkSource;
  inherit (_.sources.overlays) mkOverlays;
  inherit (_.strings.access) match;
  inherit (_.strings.construction) concat;
  inherit (_.strings.predicates) hasPrefix hasSuffix isString;
  inherit (_.strings.transformation) removePrefix removeSuffix unsafeDiscardStringContext;

  mkToolkit = {
    inputs,
    pkgs ? null,
    host ? {},
    sources ? {},
    prefer ? {},
    enableShorthand ? false,
    ...
  }: let
    pkgs' =
      if pkgs != null
      then pkgs
      else (mkAll {inherit inputs host;}).pkgs;

    derived = pkgsFrom {
      inherit inputs enableShorthand;
      pkgs = pkgs';
      required = true;
      prefer = _default.toolkit.prefer // prefer;
      sources = _default.toolkit.sources // sources;
    };

    defined = let
      bins = derived.binaries;
      binaries = recursiveUpdate bins {
        #> coreutils
        chmodR = "${bins.chmod} -R";
        chmodRuw = "${bins.chmod} -R u+w";
        cpa = "${bins.cp} -a --reflink=auto";
        cpaf = "${bins.cp} -af --reflink=auto"; #? force version of your cpa
        dateI = "${bins.date} -I"; #? ISO date
        dateIs = "${bins.date} -Is"; #? ISO date + time
        headn = "${bins.head} -n";
        installD = "${bins.install} -D"; #? create parent dirs
        installDm = "${bins.install} -D -m"; #? include mode (caller supplies the mode)
        installm = "${bins.install} -m"; #? include mode (caller supplies the mode)
        lnSf = "${bins.ln} -Sf"; #? force symlink
        lnsfn = "${bins.ln} -sfn";
        mkdirp = "${bins.mkdir} -p";
        mktempd = "${bins.mktemp} -d";
        mvt = "${bins.mv} -T";
        readlinkf = "${bins.readlink} -f";
        rmf = "${bins.rm} -rf";
        sortn = "${bins.sort} -n";
        sortu = "${bins.sort} -u";
        sortV = "${bins.sort} -V";
        tailf = "${bins.tail} -f";
        tailn = "${bins.tail} -n";
        teea = "${bins.tee} -a";
        wcc = "${bins.wc} -c";
        wcl = "${bins.wc} -l";
        wcw = "${bins.wc} -w";

        #> finders (modern)
        fdh = "${bins.fd} --hidden --no-ignore";
        rgi = "${bins.rg} -i";
        rg0 = "${bins.rg} --null";

        #> findutils
        find0 = "${bins.find} -print0";
        grepr = "${bins.grep} -r";
        grepri = "${bins.grep} -ri";
        sedi = "${bins.sed} -i";
        xargs0 = "${bins.xargs} -0";
        xargsr = "${bins.xargs} -r"; #? don't run if stdin is empty
        xargsI = "${bins.xargs} -I{}";

        #> git
        gitCfgFile = "${bins.git} config --file";

        #> glib
        gCall = "${bins.gdbus} call";
        gSet = "${bins.gsettings} set";
        gSetDI = "${bins.gsettings} set org.gnome.desktop.interface";

        #> gnupatch
        patchd = "${bins.patch} -d";

        #> ouch
        pack = "${bins.ouch} compress";
        unpack = "${bins.ouch} decompress";

        #> procps (very common)
        pgrepf = "${bins.pgrep} -f";
        pkillf = "${bins.pkill} -f";
        pgrepa = "${bins.pgrep} -a"; #? show full command line

        #> systemd
        journalctlUser = "${bins.journalctl} --user";
        systemctlUser = "${bins.systemctl} --user";

        #> util-linux
        loggerT = "${bins.logger} -t"; #? with tag (caller supplies the tag)
      };
    in
      {inherit binaries;}
      // optionalAttrs enableShorthand {bins = binaries;};

    helpers = {
      builders = {
        inherit
          (pkgs')
          buildEnv
          makeBinaryWrapper
          makeDesktopItem
          makeShellWrapper
          replaceVars
          runCommand
          runCommandCC
          runCommandLocal
          runCommandNoCC
          symlinkJoin
          ;
      };

      source = {
        inherit (pkgs'.lib) cleanSource cleanSourceWith fileset;
      };

      fetch = with pkgs'; {
        fromGit = fetchgit;
        fromGitHub = fetchFromGitHub;
        fromGitLab = fetchFromGitLab;
        fromUrl = fetchurl;
        fromZip = fetchzip;
        patch = fetchpatch;
        tarball = fetchTarball;
      };

      platform = {
        inherit (pkgs'.stdenv.hostPlatform) isAarch64 isLinux isDarwin isx86_64 system;
        shell = pkgs'.runtimeShell;
      };

      write = let
        inherit (pkgs') linkFarm writeShellApplication writeShellScript writeText writeTextFile;
        inherit (pkgs'.writers) writeDash writeDashBin;
      in
        {
          #? Package with bin/<name>: strict mode and shellcheck, no PATH assumptions
          bin = name: text:
            writeShellApplication {
              inherit name text;
              runtimeInputs = [];
            };

          #? Same, with packages added to PATH
          binWith = name: runtimeInputs: text:
            writeShellApplication {inherit name runtimeInputs text;};

          link = linkFarm; #? name, [{name; path;}]
          posix = writeDash; #? POSIX sh file, for ExecStart= and the like
          posixBin = writeDashBin; #? POSIX sh with bin/<name>
          script = writeShellScript; #? bash file, for ExecStart= and the like
          text = writeText;
          textFile = writeTextFile; #? supports executable, destination, etc.
        }
        // #> Expose common serializers as well
        genAttrs ["json" "toml" "yaml" "ini"]
        (name: (pkgs'.formats.${name} {}).generate);
    };
  in
    derived // defined // helpers;

  _mk = target: {
    inputs ? {},
    names ? [],
  }: let
    default = _default.inputs.${target};
  in
    mkOne {
      inherit inputs;
      inherit (default) attrs;
      names = default.names ++ names;
    };
  mkCore = _mk "core";
  mkHome = _mk "home";

  fromInputs = {
    inputs,
    system,
    input,
  }: let
    packages = {
      sys = inputs.${input}.packages.${system} or null;
      fmt = inputs.${input}.formatter.${system} or null;
    };
  in
    with packages;
      if isNotEmpty sys
      then sys
      else optionalAttrs (isNotEmpty fmt) {${input} = fmt;};

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
    via `getExe'`; when omitted, the package's declared main program or
    package name is used

  `alias`
  : optional command name to expose as a symlink package in `.alias`

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
  > pkgOf :: { inputs :: AttrSet, input :: string, target :: string?, exe :: string?, alias :: string?, pkgs :: AttrSet?, system :: string?, required :: bool? } -> { name :: string, package :: derivation, exe :: string, command :: string, alias :: derivation?, paths :: { executable :: path, binary :: path, store :: path } } | null

  # Examples
  > pkgOf { inherit `inputs` `pkgs`; `input` = _"treefmt-nix"_; `target` = _"treefmt"_; }

  ```nix
  {
    name = "treefmt";
    package = «derivation treefmt-2.x.x»;
    command = "treefmt";
    exe = "/nix/store/.../bin/treefmt";
    paths = {...};
  }
  ```

  > pkgOf { inherit `inputs` `pkgs`; `input` = _"treefmt-nix"_; }

    ```nix
    { name = "treefmt"; package = «derivation treefmt-2.x.x»; ... }
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
    alias ? null,
    discover ? false,
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
        context = "resolving system for package from input '${toString input}' or pkgs";
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
          (optionals (input != null) ["default"]) ++ suffixStripped ++ (optionals (input != null) [input])
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
          executable = let
            mainProgram = package.meta.mainProgram or null;
          in
            if exe != null
            then getExe' package exe
            else if mainProgram != null
            then getExe' package mainProgram
            else getExe' package (package.pname or check.name);
          binary = "${getBin package}/bin";
          store = package.outPath or "${package}";
        };

        command = unsafeDiscardStringContext (baseNameOf paths.executable);

        revision =
          if check.source != "nixpkgs" && input != null
          then let
            flake = init.inputs.${input};
          in
            flake.shortRev or (flake.rev or null)
          else null;

        #> Lazy: `readDir` only runs if `bins` is forced and `discover` is set.
        #> Forcing it realises the package at eval time (IFD).
        discovered = let
          entries = readDir paths.binary;
          visible = filter (name: !(hasPrefix "." name)) (attrNames entries);
        in
          genAttrs visible (name: "${paths.binary}/${name}");
        version = getVersion {
          inherit package revision;
          exe = paths.executable;
          args = versionArgs;
        };
      in {
        inherit (check) name source;
        inherit command package paths revision;

        exe = paths.executable;
        exeOf = executable: getExe' package executable;

        bins =
          if discover
          then discovered
          else {${command} = paths.executable;};

        inherit version;

        description =
          if description != null && description != ""
          then description
          else package.meta.description or null;

        alias =
          if alias == null
          then null
          else
            init.source.legacy.linkFarm alias [
              {
                name = "bin/${alias}";
                path = paths.executable;
              }
            ];
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

    `sources` maps null | string | {input, target, exe, alias, description, versionArgs}
    `{codex = "llm-agents"; "hermes-agent" = "llm-agents";}` - this lets
    ambiguous names (present in more than one input) resolve to a specific
    input per-package, rather than relying on a single global priority
    order. Each package's own name is passed to `pkgOf` as `target`, so it
    resolves exactly that attribute rather than falling back to `"default"`
    or a suffix-stripped guess.

    Returns canonical package records under `records`, alongside grouped
    outputs: `binaries`, `commands`, `versions`, `origins`, `descriptions`,
    `packages`, and `names`. Package records are not flattened into the
    top-level namespace. Set `enableShorthand = true` only when a caller
    explicitly needs the legacy `bins`, `cmds`, and `vr3n` aliases.

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
    { records.treefmt = {name = "treefmt"; package = «derivation»; ...}; names = ["treefmt"]; packages = [«derivation»]; binaries = {...}; }
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
    { records = { codex = {...}; hermes-agent = {...}; openclaw = {...}; opencode = {...}; }; names = [...]; packages = [«codex» «hermes-agent» «openclaw» «opencode»]; binaries = {...}; }
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
    prefer ? {},
    enableShorthand ? false,
  }: let
    init = let
      prep = value:
        if value == null
        then {}
        else if isString value
        then {input = value;}
        else value;

      process = target: value: let
        source = prep value;
      in
        pkgOf (
          {
            inherit inputs pkgs required;
            alias = source.alias or null;
            description = source.description or null;
            discover = source.discover or false;
            exe = source.exe or null;
            input = source.input or null;
            target = source.target or target;
            versionArgs = source.versionArgs or null;
          }
          // optionalAttrs (system != null) {inherit system;}
        );
    in
      filterAttrs (_: record: record != null) (mapAttrs process sources);

    records = let
      #> Keep only aliases where the target actually exists and isn't null
      valid =
        filterAttrs
        (name: target: init ? ${target} && init.${target} != null)
        aliases;

      #> Rename the keys to the alias names while pulling the values from init
      resolved =
        mapAttrs' (name: target: nameValuePair name init.${target})
        valid;
    in
      init // resolved;

    groups = {
      binaries = let
        merged = mergeSafe (map (record: record.bins) (attrValues init));
        pick = command: package:
          init.${package}.bins.${command}
          or (throw "pkgsFrom: prefer.${command} = \"${package}\", but that package provides no `${command}`");
      in
        merged // mapAttrs pick prefer;
      commands = mapAttrs (_: record: record.command) records;
      versions = mapAttrs (_: record: record.version) records;
      origins = mapAttrs (_: record: record.source) records;
      descriptions = mapAttrs (_: record: record.description) records;
      packages =
        filter
        (package: !(elem (package.pname or package.name or "") exclude))
        (map (record: record.package) (attrValues init));
      names = attrNames records;
    };

    shorthand = optionalAttrs enableShorthand {
      bins = groups.binaries;
      cmds = groups.commands;
      vr3n = groups.versions;
    };
  in
    groups // shorthand // {inherit records;};

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
    src ? {},
    host ? {},
    inputs ? {},
    system ? null,
    config ? {},
    coreNames ? [],
    homeNames ? [],
    ...
  } @ args: let
    inputs' = normalizeInputs (
      if isNotEmpty inputs
      then inputs
      else {}
    );

    system' = getSystemOrDefault {
      inputs = inputs';
      inherit host system;
    };

    # Normalize host package settings across all supported alias locations
    pkgSettings =
      host.settings.forNixpkgs or host.settings.pkg or host.settings.packages or host.packages or host.pkg
          or {};

    config' = _default.inputs.config // pkgSettings // config;

    # Dynamically pick input based on `unstable = true`
    nixpkgsInput =
      if pkgSettings.unstable or false
      then inputs'.nixpkgs-unstable or inputs'.nixpkgs
      else inputs'.nixpkgs;

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
          input = nixpkgsInput;
        };
      in
        optionalAttrs (isNotEmpty src) (src.flake.source or src.source);
    in
      source
      // {
        inputs = inputs';
        legacyPackages = mapAttrs (sys: base: base // ((bySystem packages).${sys} or {})) (
          nixpkgsInput.legacyPackages or {}
        );
      };

    resolved = {
      inherit packages overlays;

      inputs =
        if inputs'.home-manager != {}
        then inputs'
        else "Inputs can be see via the flake: > :lf . > lib.inputs";

      config = config';
      nixpkgs = nixpkgs';

      # Export kernel string or derivation reference for downstream module consumption
      kernel = pkgSettings.kernel or null;

      pkgs = import nixpkgsInput {
        inherit overlays;
        system = system';
        config = config';
      };
    };
  in
    src // args // resolved;
in
  with meta.exports;
    internal
    // {
      __docs = meta.doc;
      __rootAliases = external;
    }
