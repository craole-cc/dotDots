{host, ...}: {
  system.stateVersion = host.stateVersion or "25.05";
  nix = {
    # gc = {
    #   automatic = true;
    #   persistent = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 5d";
    # };

    # optimise = {
    #   automatic = true;
    #   persistent = true;
    #   dates = "weekly";
    # };

    settings = {
      # auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      max-jobs = host.specs.cpu.cores or "auto";
      # substituters = ["https://cache.nixos.org/"];
      # trusted-substituters = [
      #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #   "https://hydra.nixos.org/"
      # ];
      trusted-users = ["root" "@wheel"];
    };

    # extraOptions = ''
    #   download-buffer-size = 524288000
    # '';
  };

  nixpkgs = {
    hostPlatform = host.platform;
    config.allowUnfree = host.packages.allowUnfree or false;
  };
}
