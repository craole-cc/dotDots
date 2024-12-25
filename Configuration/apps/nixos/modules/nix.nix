{
  specialArgs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (specialArgs.host) userConfigs stateVersion system;
  inherit (lib.attrsets) attrNames;
  flake = specialArgs.paths.flake.local;
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
    activationScripts.setDotsPermissions = {
      text = ''
        #!/bin/sh
        mkdir -p ${flake}
        chown -R root:wheel ${flake}
        find ${flake} -type d -exec chmod 770 {} +
        find ${flake} -type f -exec chmod 660 {} +
        find ${flake} -type d -exec chmod g+s {} +


        for user in $(
          getent group wheel | cut -d: -f4 | tr ',' ' '
        ); do
          if [ ! -L /home/$user/dots ]; then
            ln -s /dots /home/$user/dots
          fi
          [ -f ~/.gitconfig]
        done
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${flake} 0770 root wheel -"
    "d ${flake} 2770 root wheel -"
  ];
}
