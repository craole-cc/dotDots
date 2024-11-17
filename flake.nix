{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs = {
      # url = "github:nixos/nixpkgs/nixos-24.05";
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgsUnstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgsStable = {
      url = "github:NixOS/nixpkgs/nixos-24.05";
    };
    nixosHardware = {
      url = "github:NixOS/nixos-hardware";
    };
    systems = {
      url = "github:nix-systems/default-linux";
    };
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed = {
      url = "github:Craole/nixed";
    };
  };
  outputs =
    {
      nixpkgs,
      nixDarwin,
      homeManager,
      ...
    }:
    let
      lib = nixpkgs.lib // homeManager.lib // nixDarwin.lib;
      pkg = system: nixpkgs.legacyPackages.${system};
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      dot = "/home/craole/Documents/dotfiles";
      mod = "/Configuration/apps/nixos";
      bin = dot + "/Bin";
      flakeSwitch =
        pkgs:
        pkgs.writeShellScriptBin "flake-switch" ''
          #! /bin/sh

          #| Set default message if not provided
          MESSAGE="Flake Update"
          [ "$1" ] && MESSAGE="$1"

          #| Navigate to the directory where the flake is located
          pushd ${dot} || exit

          #| Add all changes and commit with the provided or default message
          git add --all
          git commit --message "$MESSAGE"

          #| Rebuild NixOS configuration using flakes
          sudo nixos-rebuild switch --flake .

          #| Return to the previous directory
          popd
        '';
      flakeUpdate = pkgs.writeShellScriptBin "flake-update" ''
        #! /bin/sh

        # Set default message if not provided
        MESSAGE="Flake Update"
        [ "$1" ] && MESSAGE="$1"

        # Navigate to the directory where the flake is located
        pushd ${dot} || exit

        # Add all changes and commit with the provided or default message
        git add --all
        git commit --message "$MESSAGE"

        # Rebuild NixOS configuration using flakes
        sudo nixos-rebuild switch --flake .

        # Return to the previous directory
        popd
      '';
      variables = {
        DOTS = dot;
        DOTS_BIN = bin;
        DOTS_NIX = dot + mod;
      };
      shellAliases = {
        Flake = ''pushd ${dot} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
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
      modulesCore = ./. + mod;
      modulesHome = {
        home-manager = {
          backupFileExtension = "BaC";
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
      modulesNixos = [
        modulesCore
        modulesHome
        homeManager.nixosModules.home-manager
      ];
      modulesDarwin = [
        modulesCore
        modulesHome
        homeManager.darwinModules.home-manager
      ];
      args = {
        paths = {
          inherit
            dot
            mod
            bin
            ;
        };
      };
    in
    {
      nixosConfigurations = {
        preci =
          let
            system = "x86_64-linux";
          in
          lib.nixosSystem {
            inherit system;
            modules = modulesNixos ++ [
              {
                environment = {
                  inherit variables shellAliases pathsToLink;
                  systemPackages = [
                    flakeUpdate
                    (flakeSwitch pkg system)
                  ];
                };
                # DOTS.hosts.Preci.enable = true;
              }
            ];
            specialArgs = args;
          };

        dbook = lib.nixosSystem {
          system = "x86_64-linux";
          modules = modulesNixos ++ [
            {
              # DOTS.hosts.DBook.enable = true;
            }
          ];
          # modules = [ (hostModules + "/dbook") ] ++ modulesNixos;
        };
      };

      darwinConfigurations = {
        MBPoNine = lib.darwinSystem {
          system = "x86_64-darwin";
          modules = modulesDarwin ++ [ { DOTS.hosts.MBPoNine.enable = true; } ];
        };
      };
    };
}
