{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixed = {
    #   url = "github:Craole/nixed";
    #   flake = false;
    # };
  };
  outputs =
    inputs@{ self, ... }:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.home-manager.nixosModules) home-manager;
      paths = {
        src = ./Configuration/apps/nixos;
        core = with core; {
          src = paths.src + "/home";
          lib = src + "/libraries";
          opt = src + "/options";
          cfg = src + "/configurations";
        };
        home = with home; {
          src = paths.src + "/home";
          lib = src + "/libraries";
          opt = src + "/options";
          cfg = src + "/configurations";
        };
      };

      mods = {
        core =
          (with paths.core; [
            lib
            opt
          ])
          ++ [
            home-manager
            {
              home-manager = {
                backupFileExtension = "BaC";
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
          ];
        home = with paths.home; [
          lib
          opt
        ];
      };
    in
    {
      nixosConfigurations =
        let
          inherit (paths.core) cfg;
        in
        {
          preci = nixosSystem {
            system = "x86_64-linux";
            modules = mods.core ++ [ (cfg + "/preci") ];
          };
          dbook = nixosSystem {
            system = "x86_64-linux";
            modules = mods.core ++ [ (cfg + "/dbook") ];
          };
        };
    };
}
