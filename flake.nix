{
  description = "NixOS Configuration Flake";
  inputs = {
    nixosStable.url = "nixpkgs/nixos-24.05";
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosHardware.url = "github:NixOS/nixos-hardware";
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    systems.url = "github:nix-systems/default-linux";
    nixed.url = "github:Craole/nixed";
    # redyFonts = {
    #   url = "github:redyf/font-flake";
    # };
  };
  outputs =
    inputs@{
      self,
      nixosStable,
      nixosUnstable,
      homeManager,
      nixDarwin,
      ...
    }:
    let
      flake = self;
      paths = {
        dot = "/home/craole/Documents/dotfiles";
        mod = "/Configuration/apps/nixos";
        bin = "/Bin";
      };
      variables = with paths; {
        DOTS = dot;
        DOTS_BIN = dot + bin;
        DOTS_NIX = dot + mod;
      };
      shellAliases = {
        Flake = ''pushd ${paths.dot} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
      };
      pathsToLink = with paths; [
        (dot + bin + "/base")
        (dot + bin + "/core")
        (dot + bin + "/import")
        (dot + bin + "/interface")
        (dot + bin + "/misc")
        (dot + bin + "/packages")
        (dot + bin + "/project")
        (dot + bin + "/tasks")
        (dot + bin + "/template")
        (dot + bin + "/utility")
      ];
      modulesCore = ./. + paths.mod;
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
        inherit
          flake
          paths
          ;
      };

      mkNixpkgs =
        {
          system,
          repo ? "unstable",
          nixpkgs-stable ? nixosStable,
          nixpkgs-unstable ? nixosUnstable,
          allowUnfree ? true,
          allowAliases ? true,
          allowHomeManager ? true,
          extraConfig ? { },
          extraAttrs ? { },
        }:
        let
          mkPkgs =
            repo:
            import repo {
              inherit system;
              config = {
                inherit allowUnfree allowAliases;
              } // extraConfig;
            };
          nixpkgs = if repo == "stable" then nixpkgs-stable else nixpkgs-unstable;
          pkgs = mkPkgs nixpkgs;
          lib = if allowHomeManager then nixpkgs.lib // homeManager.lib else nixpkgs.lib;
          unstablePkgs = mkPkgs nixpkgs-unstable;
          stablePkgs = mkPkgs nixpkgs-stable;
        in
        pkgs.extend (
          final: prev:
          {
            stable = stablePkgs;
            unstable = unstablePkgs;
            inherit lib;
          }
          // extraAttrs
        );

      mkNixos =
        {
          system,
          name ? "nixos",
          repo ? "unstable",
          allowHomeManager ? true,
          allowUnfree ? true,
          extraArgs ? args,
        }:
        let
          pkgs = mkNixpkgs { inherit system; };
          lib = pkgs.lib;
          specialArgs = { } // extraArgs;
          modules =
            (
              if allowHomeManager then
                [
                  modulesCore
                  modulesHome
                  homeManager.nixosModules.home-manager
                ]
              else
                [ modulesCore ]
            )
            ++ [
              {
                #  DOTS.hosts.${name}.enable = true;
                environment = {
                  inherit variables shellAliases pathsToLink;
                };
              }
            ];
        in
        lib.nixosSystem {
          inherit
            system
            pkgs
            lib
            specialArgs
            modules
            ;
        };

      mkCore =
        {
          system,
          name ? "nixos",
          repo ? "unstable",
          allowHomeManager ? true,
          allowUnfree ? true,
          specialArgs ? args,
        }:
        let
          isDarwin = builtins.elem system [
            "x86_64-darwin"
            "aarch64-darwin"
          ];
          pkgs = mkNixpkgs { inherit system; };
          lib = pkgs.lib;
          modules =
            [ modulesCore ]
            ++ [
              (
                if allowHomeManager then
                  [
                    modulesHome
                    (if with homeManager; isDarwin then darwinModules.home-manager else nixosModules.home-manager)
                  ]
                else
                  [ ]
              )
            ]
            ++ [
              {
                #  DOTS.hosts.${name}.enable = true;
                environment = {
                  inherit variables shellAliases pathsToLink;
                };
              }
            ];
        in
        if isDarwin then
          lib.darwinSystem {
            inherit
              system
              pkgs
              lib
              specialArgs
              modules
              ;
          }
        else
          lib.nixosSystem {
            inherit
              system
              pkgs
              lib
              specialArgs
              modules
              ;
          };
    in
    {
      nixosConfigurations = {
        preci = mkCore {
          name = "preci";
          system = "x86_64-linux";
        };
        dbook = mkCore {
          name = "dbook";
          system = "x86_64-linux";
        };
      };

      darwinConfigurations = {
        MBPoNine = mkCore {
          name = "MBPoNine";
          system = "x86_64-darwin";
        };
      };

      # TODO create mkHome for standalone home manager configs

      # darwinConfigurations = {
      #   MBPoNine =
      #     let
      #       system = "x86_64-linux";
      #       packs = packages { inherit system; };
      #       pkgs = packs.unstable;
      #       lib = packs.libraries;
      #     in
      #     lib.darwinSystem {
      #       system = "x86_64-darwin";
      #       modules = modulesDarwin ++ [ { DOTS.hosts.MBPoNine.enable = true; } ];
      #     };
      # };
    };
}
