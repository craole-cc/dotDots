{
  description = "NixOS Configuration Flake";

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import inputs.systems);
      paths = import ./Modules/nixos/base/paths.nix;
      mkConfig = import paths.libraries.mkConf {
        inherit self inputs paths;
      };
    in
    {
      imports = [ ./Modules/nixos ];
      packages = eachSystem (system: rec {
        inherit self;
        default = hello;
        hello = nixpkgs.legacyPackages.${system}.hello;
      });

      nixosConfigurations = {
        # inherit paths;
        # flake = ./.;
        QBX = mkConfig "QBX" { };
        # Preci = mkConfig "Preci" { };
        # dbook = mkConfig "dbook" { };
      };
      # /nix/store/nsv6f087zz15xjvgm41x2zcyimdz1jsi-source/Modules/nixos/libraries/helpers/mkConfig.nix
    };

  inputs = {
    #| Core
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
    };
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosStable.url = "nixpkgs/nixos-24.11";
    nixosHardware.url = "github:NixOS/nixos-hardware";
    nixSystems.url = "github:nix-systems/default";
    nixPackages = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    #| Utilities
    # flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-unified.url = "github:srid/nixos-unified";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # agenix.url = "github:ryantm/agenix";
    # nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #| Software inputs
    # github-nix-ci.url = "github:juspay/github-nix-ci";
    # nixos-vscode-server = {
    #   url = "github:nix-community/nixos-vscode-server";
    #   flake = false;
    # };
    # omnix.url = "github:juspay/omnix";
    # hyprland.url = "github:hyprwm/Hyprland/v0.46.2";
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "homeManager";
      };
    };
    stylix.url = "github:danth/stylix";

    #| Neovim
    # nixvim = {
    #   url = "github:nix-community/nixvim";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Devshell
    # git-hooks = {
    #   url = "github:cachix/git-hooks.nix";
    #   flake = false;
    # };

    #| Templates
    nixed.url = "github:Craole/nixed";

  };
}
