{
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (host) stateVersion;
  inherit (host.specs) platform cpu;
  inherit (host.packages) allowUnstable allowUnfree allowSmall;
in {
  nix = {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/craole/Configuration/configuration.nix"
    ];
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };

    optimise = {
      automatic = true;
      persistent = true;
      dates = "weekly";
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      max-jobs = cpu.cores;
      substituters = ["https://cache.nixos.org/"];
      trusted-substituters = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "https://hydra.nixos.org/"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    extraOptions = ''
      download-buffer-size = 524288000
    '';
  };

  nixpkgs = {
    config.allowUnfree = allowUnfree;
    hostPlatform = platform;
  };

  system = {
    inherit stateVersion;

    autoUpgrade = {
      enable = true;
      channel = let
        # Determine the channel branch name
        # Logic:
        # 1. Base is either "unstable" or the stateVersion (e.g., "24.11")
        # 2. If size is "small", append "-small" (e.g., "nixos-24.11-small" or "nixos-unstable-small")
        kind =
          if allowUnstable
          then "unstable"
          else stateVersion;
        base =
          if allowSmall
          then "${kind}-small"
          else kind;
        branch = "nixos-${base}";
      in "https://nixos.org/channels/${branch}";
      allowReboot = true;
      dates = "daily";
      persistent = true;
      rebootWindow = {
        lower = "01:00";
        upper = "05:00";
      };
    };
  };
}
