{lib}: let
  inherit (lib.attrsets) attrNames mapAttrsToList;
  inherit (lib.strings) concatLines escapeShellArg;

  mkEnvLines = env:
    concatLines (mapAttrsToList (name: value: "${name}=${escapeShellArg value}") env);

  mkScriptPackage = {
    pkgs,
    name,
    file,
    env ? {},
  }:
    pkgs.writeShellScriptBin name ''
      ${mkEnvLines env}
      ${builtins.readFile file}
    '';

  mkAliasPackage = {
    pkgs,
    name,
    target,
  }:
    pkgs.writeShellScriptBin name ''
      exec ${target} "$@"
    '';

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
      '') names
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

      ${builtins.readFile ./mission-control.sh}
    '';
in {
  inherit mkAliasPackage mkMissionControl mkScriptPackage;
}
