{
  specialArgs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs.host) userConfigs stateVersion system;
  inherit (lib.attrsets) attrNames;
  inherit (lib.strings) makeBinPath;
  inherit (specialArgs.paths) flake scripts;

in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ] ++ (attrNames userConfigs);
    };
    extraOptions = ''
      download-buffer-size = 4096
    '';
  };

  nixpkgs = {
    hostPlatform = system;
  };

  system = {
    inherit stateVersion;
    activationScripts.setDotsPermissions.text = ''
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

      ${pkgs.bash}/bin/bash ${scripts.dots} \
        --source ${flake.local} \
        --target ${flake.root} \
        --verbose \
        --strict
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${flake.root} 0770 root wheel -"
    "d ${flake.root} 2770 root wheel -"
  ];
}
