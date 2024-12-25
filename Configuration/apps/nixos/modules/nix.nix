{
  specialArgs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (specialArgs.host) userConfigs stateVersion system;
  inherit (lib.attrsets) attrNames;
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

  system = { inherit stateVersion; };

  systemd.tmpfiles.rules = [
    "d /dots 0770 root wheel -"
    "d /dots 2770 root wheel -"
  ];
}
