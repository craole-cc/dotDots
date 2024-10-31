{ ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
    optimise = {
      automatic = true;
      dates = [ "03:00" ];
    };

    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    # registry = lib.mapAttrs (_: v: { flake = v; }) inputs;

    settings = {
      allowed-users = [ "@wheel" ];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" ];
      system-features = [ "recursive-nix" ];
      cores = 0;
      max-jobs = "auto";
      substituters = [
        "https://nix-community.cachix.org"
        "https://nix-config.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
        "https://cache.floxdev.com"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-config.cachix.org-1:Vd6raEuldeIZpttVQfrUbLvXJHzzzkS0pezXCVVjDG4="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="
      ];

      # for direnv GC roots
      # keep-derivations = true;
      # keep-outputs = true;
    };
  };

  #@ Clear space automatically when full
  # extraOptions = ''
  #   min-free = ${toString (100 * 1024 * 1024)}
  #   max-free = ${toString (1024 * 1024 * 1024)}
  # '';

  system.stateVersion = "22.11";
}
