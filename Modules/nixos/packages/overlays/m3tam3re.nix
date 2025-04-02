{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions =
    final: prev:
    (import ../pkgs { pkgs = final; })
    // (inputs.hyprpanel.overlay final prev)
    // {
      rose-pine-hyprcursor = inputs.rose-pine-hyprcursor.packages.${prev.system}.default;
    };
  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    n8n = import ./mods/n8n.nix { inherit prev; };

    brave = prev.brave.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    };

    auto-cpufreq = inputs.nixpkgs-2744d98.legacyPackages.${prev.system}.auto-cpufreq;
    OVMF = inputs.nixpkgs-locked.legacyPackages.${prev.system}.OVMF;
    trezord = inputs.nixpkgs-2744d98.legacyPackages.${prev.system}.trezord;

    # hyprpanel = inputs.hyprpanel.packages.${prev.system}.default.overrideAttrs (prev: {
    #   version = "latest"; # or whatever version you want
    #   src = final.fetchFromGitHub {
    #     owner = "Jas-SinghFSU";
    #     repo = "HyprPanel";
    #     rev = "master"; # or a specific commit hash
    #     hash = "sha256-l623fIVhVCU/ylbBmohAtQNbK0YrWlEny0sC/vBJ+dU=";
    #   };
    # });
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  pinned-packages = final: _prev: {
    pinned = import inputs.nixpkgs-2744d98 {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  locked-packages = final: _prev: {
    locked = import inputs.nixpkgs-locked {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  master-packages = final: _prev: {
    master = import inputs.nixpkgs-master {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
