let
  src = import ./. { inherit inputs; };
  inherit (src)
    dots
    lib
    modules
    systems
    ;
  inherit (dots) envs;
  inherit (lib) mkFlake mkNixOS;
  inherit (modules) easyOverlay flakeRoot treefmt;
in
{
  description = "Dots by Nix";

  outputs =
    inputs@{ self, ... }:
    # TODO: Seperate the core and home configs
    # TODO: Move away from using flakeModules
    mkFlake { inherit inputs; } {
      inherit systems;
      perSystem.imports = [ envs.devShells ];
      imports = [
        {
          config._module.args = {
            _inputs = inputs // {
              inherit (inputs) self;
            };
          };
        }
        easyOverlay
        flakeRoot
        treefmt
      ];
      flake = {
        nixosConfigurations = {
          victus = mkNixOS {
            #@ Victus by HP Gaming Laptop 15-fb1013dx
            # *** AMD Ryzen™ 5 7535HS,
            # *** NVIDIA GeForce RTX 2050,
            # *** 32GB DDR5-3200 SDRAM,
            # *** 2TB PCIe® NVMe™ M.2 SSD
          };

          preci = mkNixOS {
            #@ Dell Precison M2800
            # *** Processors: 8 × Intel® Core™ i7-4810MQ CPU @ 2.80GHz
            # *** Mesa Intel® HD Graphics 4600
            # *** 16GB SDRAM
            # *** Manufacturer: Dell Inc.
            # *** Product Name: Precision M2800
            # *** System Version: 00
            # *** Serial Number: DBDSH12
          };

          # raspi = mkNixOS {
          #   # @ Raspberry Pi 4 Model B
          #   # *** Broadcom BCM2711,
          #   # *** Quad core Cortex-A72 (ARM v8) 64-bit SoC @ 1.5GHz
          #   # *** 4GB LPDDR4-3200 SDRAM
          #   username = "craole";
          #   hostname = "raspi";
          #   extraStacks = [];
          #   extraModules = [];
          #   extraPackages = [];
          #   extraArgs = {};
          # };
        };
      };
    };

  inputs = {
    # | Primary
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    # nixpkgs-pinned.url = "github:NixOS/nixpkgs/b8b232ae7b8b144397fdb12d20f592e5e7c1a64d";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # | Per System
    flake-root.url = "github:srid/flake-root";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # pre-commit-hooks = {
    #   url = "github:cachix/pre-commit-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # | Utilities
    # nix-super.url = "github:privatevoid-net/nix-super";
    # deploy-rs.url = "github:serokell/deploy-rs";
    nix-index-db = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    # impermanence.url = "github:nix-community/impermanence";
    # catppuccinifier = {
    #   url = "github:lighttigerXIV/catppuccinifier";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # | Secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix = {
    #   url = "github:ryantm/agenix";
    #   inputs.home-manager.follows = "home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # dotsecrets = {
    #   url = "github:Craole/secrets-by-nix";
    #   flake = false;
    # };

    # | KDE
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # | Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprcontrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # | Development
    # rust-overlay = {
    #   url = "github:oxalica/rust-overlay";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # helix = {
    #   url = "github:helix-editor/helix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.rust-overlay.follows = "rust-overlay";
    # };
  };
}
