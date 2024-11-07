{
  description = "NixOS Configuration Flake";
  outputs =
    inputs@{ ... }:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.darwin.lib) darwinSystem;
      inherit (inputs.home-manager.nixosModules) home-manager;

      dot = (__getEnv "HOME") + "/Documents/dotfiles";
      mod = "/Configuration/apps/nixos";
      bin = dot + "/Bin";

      variables = {
        DOTS = dot;
        DOTS_BIN = bin;
        DOTS_NIX = dot + mod;
      };
      shellAliases = {
        Flake = "sudo nixos-rebuild switch --flake ${dot}";
      };

      pathsToLink = [
        (bin + "/base")
        (bin + "/core")
        (bin + "/import")
        (bin + "/interface")
        (bin + "/misc")
        (bin + "/packages")
        (bin + "/project")
        (bin + "/tasks")
        (bin + "/template")
        (bin + "/utility")
      ];

      modules = ./. + mod;
      coreModules = [ modules ] ++ homeModules;
      homeModules = [
        home-manager
        {
          home-manager = {
            backupFileExtension = "BaC";
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
      ];
    in
    {
      nixosConfigurations = {
        preci = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules ++ [
            {
              environment = {
                inherit variables shellAliases pathsToLink;
              };
              # DOTS.hosts.Preci.enable = true;
            }
          ];
        };

        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules ++ [ { DOTS.hosts.DBook.enable = true; } ];
          # modules = [ (hostModules + "/dbook") ] ++ coreModules;
        };
      };

      darwinConfigurations = {
        MBPoNine = darwinSystem {
          system = "x86_64-darwin";
          modules = homeModules ++ [ { DOTS.hosts.MBPoNine.enable = true; } ];
        };
      };
    };

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed = {
      url = "github:Craole/nixed";
      flake = false;
    };
  };
}
