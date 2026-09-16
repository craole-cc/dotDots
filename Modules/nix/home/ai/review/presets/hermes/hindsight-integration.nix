{
  lix,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  inherit (pkgs) coreutils writeShellApplication;
in {
  packages = [
    (writeShellApplication {
      name = "configure-hindsight";
      runtimeInputs = [coreutils];
      text = readFile ./configure-hindsight.sh;
    })
  ];
}
