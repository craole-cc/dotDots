{
  specialArgs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (specialArgs.host) userConfigs stateVersion system;
  inherit (lib.attrsets) attrNames;
  inherit (specialArgs.paths) flake;
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
      #!/bin/sh
      mkdir -p ${flake.root}
      chown -R root:wheel ${flake.root}
      find ${flake.root} -type d -exec chmod 770 {} +
      find ${flake.root} -type f -exec chmod 660 {} +
      find ${flake.root} -type d -exec chmod g+s {} +


      for user in $(getent group wheel | cut -d: -f4 | tr ',' ' '); do
        case "$user" in "root") continue;; esac
        [ -L "/home/$user/.dots" ] ||
          ln --symbolic "${flake.root}" "/home/$user/.dots"
      done
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${flake.root} 0770 root wheel -"
    "d ${flake.root} 2770 root wheel -"
  ];
}
