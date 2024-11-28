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
      packages =
        {
          system,
          repo ? "unstable",
          allowHomeManager ? true,
          allowUnfree ? true,
        }:
        let
          nixpkgs = if repo == "stable" then inputs.nixosStable else inputs.nixosUnstable;
          mkPkgs =
            repo:
            import repo {
              inherit system;
              config = {
                inherit allowUnfree;
              };
            };
          mkLibs =
            repo:
            let
              libs = {
                default = if allowHomeManager then repo.lib // homeManager.lib else repo.lib;
                darwin = nixDarwin.lib;
              };
            in
            if
              builtins.elem system [
                "x86_64-darwin"
                "aarch64-darwin"
              ]
            then
              with libs; default // darwin
            else
              libs.default;
        in
        {
          default = mkPkgs nixpkgs;
          stable = mkPkgs nixosStable;
          unstable = mkPkgs nixosUnstable;
          libraries = mkLibs nixpkgs;
        };
      args = {
        inherit
          flake
          paths
          ;
      };

      mkNixpkgs =
        {
          system,
          repo,
          allowUnfree ? true,
        }:
        import repo {
          inherit system;
          config = {
            inherit allowUnfree;
          };
        };

      mkPkgsOverlays =
        {
          system,
          nixpkgs-stable ? nixosStable,
          nixpkgs-unstable ? nixosUnstable,
          allowUnfree ? true,
          allowAliases ? true,
          extraConfig ? { },
          extraAttrs ? { },
        }:
        let
          mkPkgs =
            repo:
            import repo {
              inherit system;
              config = {
                inherit
                  allowUnfree
                  allowAliases
                  ;
              } // extraConfig;
            };
          unstablePkgs = mkPkgs nixpkgs-unstable;
          stablePkgs = mkPkgs nixpkgs-stable;
        in
        unstablePkgs.extend (
          final: prev:
          {
            stable = stablePkgs;
            unstable = unstablePkgs;
          }
          // extraAttrs
        );
      # {
      #   inherit unstable stable;
      #   default = unstable;
      # }
      # // extraAttrs;

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
          inherit (builtins) elem;
          nixpkgs = if repo == "stable" then nixosStable else nixosUnstable;
          sets = {
            libraries = if allowHomeManager then nixpkgs.lib // homeManager.lib else nixpkgs.lib;
            packages = mkPkgsOverlays { inherit system; };
          };
          pkgs = sets.packages.default;
          # pkgs = sets.packages;
          lib = sets.libraries;
          specialArgs = {
            inherit sets;
          } // extraArgs;
        in
        lib.nixosSystem {
          inherit
            system
            pkgs
            lib
            specialArgs
            ;
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
        };
    in
    {
      nixosConfigurations = {
        preci = mkNixos {
          name = "preci";
          system = "x86_64-linux";
        };
      };
      # nixosConfigurations = {
      #   preci =
      #     let
      #       system = "x86_64-linux";
      #       packs = packages { inherit system; };
      #       pkgs = packs.default;
      #       lib = packs.libraries;
      #       specialArgs = {
      #         inherit packs;
      #       } // args;
      #     in
      #     lib.nixosSystem {
      #       inherit
      #         system
      #         pkgs
      #         lib
      #         specialArgs
      #         ;
      #       modules = modulesNixos ++ [
      #         {
      #           environment = {
      #             inherit variables shellAliases pathsToLink;
      #           };
      #           # DOTS.hosts.Preci.enable = true;
      #         }
      #       ];
      #     };

      #   dbook =
      #     let
      #       system = "x86_64-linux";
      #       packs = packages { inherit system; };
      #       pkgs = packs.unstable;
      #       lib = packs.libraries;
      #     in
      #     lib.nixosSystem {
      #       system = "x86_64-linux";
      #       modules = modulesNixos ++ [
      #         {
      #           # DOTS.hosts.DBook.enable = true;
      #         }
      #       ];
      #       # modules = [ (hostModules + "/dbook") ] ++ modulesNixos;
      #     };
      # };

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
