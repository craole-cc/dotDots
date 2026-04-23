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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    treefmt-nix = {
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    blueprintOutputs = inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
    };
  in
    blueprintOutputs
    // {
      overlays = {
        default = import ./modules/packages/overlays {
          inherit (blueprintOutputs) packages;
        };
        shared-nixpkgs = import ./modules/packages/overlays/shared.nix {
          inherit (blueprintOutputs) mkPackagesFor;
        };
      };
      nixosModules = {
        openclaw = import ./modules/openclaw;
        default = import ./modules/openclaw;
      };
    };
}
