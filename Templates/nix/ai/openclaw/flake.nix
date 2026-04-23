{
  description = "OpenClaw — a hardened NixOS service flake";

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "config";
    };
  # outputs = inputs: let
  #   openclaw = {pkgs, ...}: let
  #     system = pkgs.stdenv.hostPlatform.system;
  #   in {
  #     _module.args.openclawPackage =
  #       inputs.self.packages.${system}.openclaw;
  #     imports = [
  #       inputs.sops.nixosModules.sops
  #       ./modules/openclaw
  #     ];
  #   };
  #   blueprint = inputs.blueprint {
  #     inherit inputs;
  #     prefix = "config";
  #     nixpkgs.config.allowUnfree = true;
  #   };
  # in
  #   blueprint
  #   // {
  #     overlays = {
  #       default = import ./modules/overlays {
  #         inherit (blueprint) packages;
  #       };
  #       shared-nixpkgs = import ./modules/overlays/shared.nix {
  #         inherit (blueprint) mkPackagesFor;
  #       };
  #     };
  #     nixosModules = {
  #       inherit openclaw;
  #       default = openclaw;
  #     };
  #   };
}
