{
  names,
  print,
  commands,
  versions,
  origins,
  env,
  lix,
  pkgs,
  ...
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.filesystem.access) readFile;

  start = writeScriptBin "start" (readFile ./start.sh);
  help = writeScriptBin "help" (readFile ./help.sh);
in {
  inherit start help;
  packages = [start help];
  shellHook = ''
    ${print.title "Hermes"}
    ${print.subtitle "Surfaces"}
    ${print.table {
      columns = ["name" "version" "source"];
      rows =
        map (name: [
          (commands.${name} or name)
          (versions.${name} or "?")
          (origins.${name} or "?")
        ])
        names;
    }}

    if [ -t 1 ]; then
      case "${toString env.AUTO_START}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
}
