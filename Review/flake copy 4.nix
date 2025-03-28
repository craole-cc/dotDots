{
  description = "NixOS Configuration Flake";

  inputs = {
    #| Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-unified.url = "github:srid/nixos-unified";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #| Software inputs
    github-nix-ci.url = "github:juspay/github-nix-ci";
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omnix.url = "github:juspay/omnix";
    hyprland.url = "github:hyprwm/Hyprland/v0.46.2";
    # plasmaManager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";

    #| Neovim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Devshell
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      flake = false;
    };

    #| Templates
    nixed.url = "github:Craole/nixed";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      imports = [ ./Modules/nixos ];
      packages = eachSystem (system: rec {
        inherit self;
        default = hello;
        hello = nixpkgs.legacyPackages.${system}.hello;
      });
    };
  # inputs@{ self, ... }:
  # inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  #   debug = true;
  #   systems = [
  #     "x86_64-linux"
  #     "aarch64-linux"
  #     "aarch64-darwin"
  #   ];
  #   imports = [ ./Modules/nixos ];
  #   perSystem =
  #     { lib, system, ... }:
  #     {
  #       # Make our overlay available to the devShell
  #       # "Flake parts does not yet come with an endorsed module that initializes the pkgs argument.""
  #       # So we must do this manually; https://flake.parts/overlays#consuming-an-overlay
  #       _module.args.pkgs = import inputs.nixpkgs {
  #         inherit system;
  #         overlays = lib.attrValues self.overlays;
  #         config.allowUnfree = true;
  #       };
  #     };

  #   # https://omnix.page/om/ci.html
  #   flake.om.ci.default.ROOT = {
  #     dir = ".";
  #     steps.flake-check.enable = false; # Doesn't make sense to check nixos config on darwin!
  #     steps.custom = { };
  #   };
  # };
}
