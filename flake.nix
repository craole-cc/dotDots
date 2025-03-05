{
  description = "Development environment for qbx host with treefmt2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "utils";
      };
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
  };

  outputs =
    inputs@{
      self,
      utils,
      home-manager,
      nixos-hardware,
      ...
    }:
    let
      pkgs = self.pkgs.x86_64-linux.nixpkgs;
      mkApp = utils.lib.mkApp;
    in
    utils.lib.mkFlake {

      inherit self inputs;

      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      channelsConfig = {
        allowUnfree = true;
      };

      hosts = {
        qbx = {
          system = "x86_64-linux";
          modules = [ ./Modules/nixos/configurations/hosts/qbx ];
        };
      };
    };
}
