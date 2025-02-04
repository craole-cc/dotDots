{
  specialArgs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.strings) makeBinPath;
  inherit (specialArgs.paths) flake scripts;

in
{
  system.activationScripts.setDotsPermissions.text = ''
    #@ Ensure required commands are available
    PATH=$PATH:${
      makeBinPath (
        with pkgs;
        [
          coreutils
          findutils
          fd
          rsync
          gnused
          gawk
          getent
          diffutils
          eza
          trashy
        ]
      )
    }

    . ${scripts.dots} \
      --source ${flake.local} \
      --target ${flake.root} \
      --verbose \
      --strict
  '';

  systemd.tmpfiles.rules = [
    "d ${flake.root} 0770 root wheel -"
    "d ${flake.root} 2770 root wheel -"
  ];
}
