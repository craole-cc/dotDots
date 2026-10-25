{
  pkgs,
  lix,
}: let
  inherit (lix.filesystem.access) readFile;
in
  pkgs.writeText "dotdots-vscode-wallpaper.js" (readFile ./wallpaper.js)
