{
  lix,
  pkgs,
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.filesystem.access) readFile;

  scripts = {
    start = writeScriptBin "start" (readFile ./start.sh);
    show-help = writeScriptBin "show-help" (readFile ./help.sh);
  };
in
  scripts
  // {
    packages = with scripts; [start show-help];
  }
