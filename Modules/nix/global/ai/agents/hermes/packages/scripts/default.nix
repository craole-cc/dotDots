{
  lix,
  pkgs,
  print,
  utils,
  extraCommands ? [],
  ...
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.filesystem.access) readFile;
  inherit (utils) names commands descriptions;

  helpContent = ''
    #!/bin/sh
    set -eu
    ${print.title "Hermes Agent"}
    ${print.table {
      columns = ["Command" "Description"];
      rows =
        (map (name: [
            (commands.${name} or name)
            (descriptions.${name} or "?")
          ])
          names)
        ++ extraCommands;
    }}
    echo
    echo "  start [--no-confirm]"
    echo "  show-help"
    echo
    echo "  HERMES_HOME=''${HERMES_HOME:-unset}"
  '';

  scripts = {
    start = writeScriptBin "start" (readFile ./start.sh);
    show-help = writeScriptBin "show-help" helpContent;
  };
in
  scripts
  // {
    packages = with scripts; [start show-help];
  }
