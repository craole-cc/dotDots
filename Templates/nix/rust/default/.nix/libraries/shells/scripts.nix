{
  lib,
  paths ? {},
  ...
}: let
  inherit (lib.attrsets) attrNames listToAttrs mapAttrsToList nameValuePair;
  inherit (lib.filesystem) readDir;
  inherit (lib.lists) elem filter findFirst head last optional;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatLines joinPath escapeShellArg hasPrefix match optionalString;
  inherit (lib.trivial) readFile throwIf;

  scripts = (paths.scripts or {}) // {missionControl = ./mission-control.sh;};

  setMarker = {path ? paths.flake}: path;
  setSource = stem:
    joinPath {
      inherit stem;
      root = paths.templates.default;
    };

  mkPackage = {
    pkgs,
    name,
    file ? null,
    env ? {},
    text ? "",
  }: let
    script = scripts.${name} or file;

    envLines = concatLines (
      mapAttrsToList
      (name: value: ''export ${name}=${escapeShellArg value}'')
      env
    );
  in
    throwIf (script == null && text == "")
    "mkPackage: no script found for '${name}'"
    (pkgs.writeShellScriptBin name ''
      ${envLines}
      ${optionalString (script != null) (readFile script)}
      ${text}
    '');

  mkPackagesFrom = {
    pkgs,
    dir ? paths.scripts.src or null,
    file ? null,
    files ? [],
    priority ? ["rs" "bash" "sh" "py" "rb"],
  }: let
    dirFiles =
      if dir == null
      then []
      else let
        entries = readDir dir;

        names =
          filter
          (name: entries.${name} == "regular")
          (attrNames entries);
      in
        map
        (name: {
          inherit name;
          path = dir + "/${name}";
        })
        names;

    explicitFiles =
      map
      (path: {
        name = baseNameOf (toString path);
        inherit path;
      })
      (
        files
        ++ optional (file != null) file
      );

    allFiles = dirFiles ++ explicitFiles;

    parseName = name: let
      parts = match "^(.*)\\.([^.]+)$" name;
    in
      if parts == null
      then {
        base = name;
        ext = null;
      }
      else {
        base = head parts;
        ext = last parts;
      };

    scriptName = item:
      (parseName item.name).base;

    scriptExt = item:
      (parseName item.name).ext;

    isSupported = item:
      elem (scriptExt item) priority;

    hasShebang = item:
      hasPrefix "#!" (readFile item.path);

    candidates =
      filter
      (item: isSupported item && hasShebang item)
      allFiles;

    bases = attrNames (
      listToAttrs (
        map
        (item: nameValuePair (scriptName item) true)
        candidates
      )
    );

    choose = base:
      findFirst
      (item: item != null)
      null
      (
        map
        (ext: let
          matches =
            filter
            (item: scriptName item == base && scriptExt item == ext)
            candidates;
        in
          if matches == []
          then null
          else head matches)
        priority
      );

    scriptEnv = ext:
      if ext == "rs"
      then ''
        case "''${RUST_LOG:-}" in
        *rust_script=*)
          ;;
        "") export RUST_LOG="rust_script=warn" ;;
        *) export RUST_LOG="''${RUST_LOG},rust_script=warn" ;;
        esac
      ''
      else "";

    mkDiscoveredScript = base: let
      chosen = choose base;
      ext = scriptExt chosen;

      source = pkgs.writeTextFile {
        name = "${base}-source";
        destination = "/share/${base}/${chosen.name}";
        executable = true;
        text = readFile chosen.path;
      };
    in
      nameValuePair base
      (pkgs.writeShellScriptBin base ''
        ${scriptEnv ext}
        exec ${source}/share/${base}/${chosen.name} "$@"
      '');
  in
    listToAttrs (map mkDiscoveredScript bases);

  mkAlias = {
    pkgs,
    name,
    target,
  }:
    pkgs.writeShellScriptBin name ''exec ${target} "$@"'';

  mkMissionControl = {
    pkgs,
    shellName,
    commands,
  }: let
    names = attrNames commands;
    commandList = concatLines (
      map (name: "  ${name}  ${commands.${name}.description}") names
    );
    commandCases = concatLines (
      map (name: ''
        ${name})
          shift
          ${commands.${name}.run}
          ;;
      '')
      names
    );
  in
    pkgs.writeShellScriptBin "mission-control" ''
            mission_list() {
              cat <<'EOF'
      Mission Control: ${shellName}

      Available commands:
      ${commandList}
      EOF
            }

            mission_run() {
              cmd="''${1:-}"

              case "$cmd" in
                ${commandCases}
                *)
                  printf 'Unknown command: %s\n' "$cmd" >&2
                  mission_list >&2
                  exit 1
                  ;;
              esac
            }

            ${readFile scripts.missionControl}
    '';

  mkFlakeReset = {pkgs ? mkPkgs {}}:
    mkPackage {
      inherit pkgs;
      name = "reset-flake";
      file = scripts.resetFlake;
    };

  mkCommands = {pkgs ? mkPkgs {}}:
    mkMissionControl {
      inherit pkgs;
      shellName = "rusti";
      commands = {
        deploy-templates = {
          description = "Sync config templates into the project";
          run = "${mkPackage {inherit pkgs;}}/bin/deploy-templates";
        };
        reset-flake = {
          description = "Reset the flake lock and generated files";
          run = "${mkFlakeReset {inherit pkgs;}}/bin/reset-flake";
        };
      };
    };
in {
  inherit
    mkAlias
    mkMissionControl
    mkFlakeReset
    mkPackage
    mkPackagesFrom
    scripts
    mkCommands
    setMarker
    setSource
    ;

  inherit paths;
}
