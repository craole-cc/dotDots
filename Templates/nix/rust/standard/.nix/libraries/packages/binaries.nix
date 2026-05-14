/**
  libraries/packages/resolve.nix

  Pure package and binary resolution helpers for lib.packages.
*/
{ lib }:
let
  inherit (lib.filesystem) readDir;
  inherit (lib.lists)
    elem
    filter
    findFirst
    head
    last
    optional
    optionals
    ;
  inherit (lib.attrsets)
    attrNames
    filterAttrs
    isAttrs
    listToAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    ;
  inherit (lib.strings)
    concatStringsSep
    parseDrvName
    escapeShellArg
    isString
    hasPrefix
    match
    ;
  inherit (lib.trivial) isNotEmpty readFile throwIf;

  mkPkg =
    {
      pkgs,
      name,
      prefix ? null,
      sep ? null,
      script ? null,
      command ? null,
    }:
    let
      shBin = pkgs.writeShellScriptBin;
      var =
        if prefix != null then
          concatStringsSep (if sep != null then sep else "_") [
            prefix
            name
          ]
        else
          name;
      val = throwIf (script != null && command != null) "mkPkg: both `script` and `command` provided, preferring `command`" (
        if command != null then
          shBin var ''exec ${command} "$@"''
        else if script != null then
          shBin var script
        else
          throw "mkPkg: must provide either `script` or `command`"
      );
    in
    val;

  mkPkgAttrs =
    args:
    let
      val = mkPkg args;
      var = val.name;
      bin = "${val}/bin/${var}";
    in
    {
      inherit var val bin;
    };

  /**
    Resolve a derivation's main executable path.

    # Inputs
    - `drv`: A derivation package with an executable output.

    # Type
    ```nix
    resolveBin :: derivation -> string
    ```

    # Examples
    ```nix
    resolveBin pkgs.hello
    # => "/nix/store/.../bin/hello"
    ```

    # Returns
    The absolute path to the derivation's main executable.
  */
  resolveBin =
    input:
    let
      resolve =
        {
          drv,
          name ? null,
          program ? null,
        }:
        let
          parsed =
            if drv ? name then
              parseDrvName drv.name
            else
              {
                name = null;
                version = null;
              };

          mainProgram =
            if program != null then
              program
            else
              drv.meta.mainProgram or (drv.NIX_MAIN_PROGRAM or (drv.pname or (if name != null then name else parsed.name)));
        in
        if mainProgram == null then
          throw "resolveBin: could not determine main program for derivation"
        else
          "${drv}/bin/${mainProgram}";
    in
    if isAttrs input && input ? drv then
      resolve input
    else if isString input then
      drv:
      resolve {
        name = input;
        inherit drv;
      }
    else
      resolve { drv = input; };

  resolveBins = packages: mapAttrs (_: resolveBin) (filterAttrs (_: isNotEmpty) packages);

  /**
    Convert an attrset of derivations into an attrset of executable paths.

    Null values are dropped first.

    # Type
    ```nix
    mkBins :: AttrSet -> AttrSet
    ```

    # Examples
    ```nix
    mkBins {
      hello = pkgs.hello;
      skipped = null;
    }
    # => { hello = "/nix/store/.../bin/hello"; }
    ```

    # Returns
    An attrset of executable paths with `null` package entries removed first.
  */
  mkBins = packages: mapAttrs (_: resolveBin) (removeAttrs packages (attrNames (filterAttrs (_: v: v == null) packages)));

  /**
    Map executable paths into shell-command helpers.

    # Type
    ```nix
    mkCmds :: AttrSet -> (string -> string) -> AttrSet
    ```

    # Examples
    ```nix
    mkCmds { hello = "/nix/store/.../bin/hello"; } (bin: "${bin} --help")
    # => {
    #   hello = "/nix/store/.../bin/hello --help";
    # }
    ```

    # Returns
    An attrset produced by mapping each binary path through the provided function.
  */
  # Logic: Map over bins, apply f, and filter out any null results automatically.
  mkCmds = bins: f: filterAttrs (_: isNotEmpty) (mapAttrs (_: bin: if isNotEmpty bin then f bin else null) bins);

  mkVr3n =
    bin:
    {
      field ? 2,
      head ? false,
      strip ? false,
      custom ? null,
    }:
    let
      base = "${bin} --version 2>&1";
      piped = if head then "${base} | head -n1" else base;
      dollar = "$";
      awk =
        if strip then "awk '{print substr(${dollar}${toString field},2)}'" else "awk '{print ${dollar}${toString field}}'";
    in
    if custom != null then custom else "${piped} | ${awk}";

  mkAlias =
    {
      pkgs,
      name,
      command ? null,
      script ? null,
      prefix ? null,
      sep ? null,
    }:
    let
      var =
        if prefix != null then
          concatStringsSep (if sep != null then sep else "_") [
            prefix
            name
          ]
        else
          name;
      val = mkPkg {
        inherit
          pkgs
          name
          prefix
          sep
          command
          script
          ;
      };
    in
    nameValuePair var val;

  mkBin =
    {
      pkgs,
      set,
      prefix ? null,
      sep ? null,
      exclude ? [ ],
    }:
    let
      resolve =
        name: value:
        if isAttrs value then
          mkAlias (
            {
              inherit
                pkgs
                name
                prefix
                sep
                ;
            }
            // value
          )
        else
          mkAlias {
            inherit
              pkgs
              name
              prefix
              sep
              ;
            command = value;
          };
    in
    mapAttrs' (name: value: resolve name value) (removeAttrs set exclude);

  mkAliases =
    aliases: concatStringsSep "\n" (mapAttrsToList (name: value: "alias ${name}=${escapeShellArg value}") aliases);

  mkPackages =
    {
      pkgs,
      dir ? null,
      file ? null,
      files ? [ ],
      priority ? [
        "rs"
        "bash"
        "sh"
        "py"
        "rb"
      ],
    }:
    let
      dirFiles = optionals (dir != null) (
        let
          entries = readDir dir;

          names = filter (name: entries.${name} == "regular") (attrNames entries);
        in
        map (name: {
          inherit name;
          path = dir + "/${name}";
        }) names
      );

      explicitFiles = map (path: {
        name = baseNameOf (toString path);
        inherit path;
      }) (files ++ optional (file != null) file);

      allFiles = dirFiles ++ explicitFiles;

      parseName =
        name:
        let
          parts = match "^(.*)\\.([^.]+)$" name;
        in
        if parts == null then
          {
            base = name;
            ext = null;
          }
        else
          {
            base = head parts;
            ext = last parts;
          };

      scriptName = item: (parseName item.name).base;
      scriptExt = item: (parseName item.name).ext;
      isSupported = item: elem (scriptExt item) priority;
      hasShebang = item: hasPrefix "#!" (readFile item.path);
      candidates = filter (item: isSupported item && hasShebang item) allFiles;
      bases = attrNames (listToAttrs (map (item: nameValuePair (scriptName item) true) candidates));

      choose =
        base:
        findFirst (item: item != null) null (
          map (
            ext:
            let
              matches = filter (item: scriptName item == base && scriptExt item == ext) candidates;
            in
            if matches == [ ] then null else head matches
          ) priority
        );

      scriptEnv =
        ext:
        if ext == "rs" then
          ''
            case "''${RUST_LOG:-}" in
            *rust_script=*)
              ;;
            "") export RUST_LOG="rust_script=warn" ;;
            *) export RUST_LOG="''${RUST_LOG},rust_script=warn" ;;
            esac
          ''
        else
          "";

      # mkDiscoveredScript = base: let
      #   chosen = choose base;
      #   ext = scriptExt chosen;

      #   source = pkgs.writeTextFile {
      #     name = "${base}-source";
      #     destination = "/share/${base}/${chosen.name}";
      #     executable = true;
      #     text = readFile chosen.path;
      #   };
      # in
      #   nameValuePair base
      #   (pkgs.writeShellScriptBin base ''
      #     ${scriptEnv ext}
      #     exec ${source}/share/${base}/${chosen.name} "$@"
      #   '');
      mkDiscoveredScript =
        base:
        let
          chosen = choose base;
          ext = scriptExt chosen;

          source = pkgs.writeTextFile {
            name = "${base}-source";
            destination = "/share/${base}/${chosen.name}";
            executable = true;
            text = readFile chosen.path;
          };

          runner = if ext == "rs" then "${pkgs.rust-script}/bin/rust-script" else source + "/share/${base}/${chosen.name}";
        in
        nameValuePair base (
          pkgs.writeShellScriptBin base ''
            ${scriptEnv ext}
            exec ${runner} ${source}/share/${base}/${chosen.name} "$@"
          ''
        );
    in
    listToAttrs (map mkDiscoveredScript bases);

  mkRustScript =
    {
      pkgs,
      name,
      src,
      dependencies ? { },
      version ? "0.1.0",
      lockFile,
    }:
    pkgs.rustPlatform.buildRustPackage {
      pname = name;
      inherit version;
      src = pkgs.runCommand "${name}-src" { } ''
        mkdir -p $out/src
        cp ${src} $out/src/main.rs
        cat > $out/Cargo.toml << EOF
        [package]
        name = "${name}"
        version = "${version}"
        edition = "2021"
        ${concatStringsSep "\n" (mapAttrsToList (n: v: "[dependencies.${n}]\n${v}") dependencies)}
        [[bin]]
        name = "${name}"
        path = "src/main.rs"
        EOF
      '';
      cargoLock.lockFile = lockFile;
    };
in
{
  inherit
    mkPkgAttrs
    mkAlias
    mkAliases
    resolveBin
    mkPackages
    resolveBins
    mkRustScript
    mkBin
    mkBins
    mkCmds
    mkVr3n
    mkPkg
    ;
}
