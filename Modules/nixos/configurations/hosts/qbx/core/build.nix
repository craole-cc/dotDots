{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  system = {
    autoUpgrade = {
      enable = true;
      dates = "18:00";
      channel = "https://nixos.org/channels/nixos-unstable";
    };
    stateVersion = "24.11";
  };
}
