{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosStable.url = "nixpkgs/nixos-24.11";
    nixosHardware.url = "github:NixOS/nixos-hardware";
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

    # flakeUtils = {
    #   url = "github:numtide/flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # flakeUtilsPlus.url = "github:gytis-ivaskevicius/flake-utils-plus";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nid = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed.url = "github:Craole/nixed";
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "homeManager";
      };
    };
    stylix.url = "github:danth/stylix";
  };
  outputs =
    { self, ... }@inputs:
    let
      paths = import ./paths.nix;
      mkConfig = import paths.libraries.mkConf {
        inherit self inputs paths;
      };
    in
    {
      # inherit paths;
      nixosConfigurations = {
        example = mkConfig "example" { };
        preci = mkConfig "preci" { };
        dbook = mkConfig "dbook" { };
      };

      # devShells.default = pkgs.mkShell {
      #   inputsFrom = [ (import ./shell.nix { inherit pkgs; }) ];
      # };

      #TODO: Create separate config directory for nix systems since the config is drastically different
      # darwinConfigurations = {
      #   MBPoNine = mkConfig "MBPoNine" { };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = mkConfig "craole" { };
    };
}
