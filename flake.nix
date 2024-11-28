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
    # systems.url = "github:nix-systems/default";
    nixed.url = "github:Craole/nixed";
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
      mods = {
        core = ./. + paths.mod;
        home = {
          forAll = {
            home-manager = {
              backupFileExtension = "BaC";
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          };
          forDarwin = homeManager.darwinModules.home-manager;
          forNixos = homeManager.nixosModules.home-manager;
        };
      };
      mkCore =
        {
          system,
          name ? "nixos",
          repo ? "unstable",
          nixpkgs-stable ? nixosStable,
          nixpkgs-unstable ? nixosUnstable,
          allowUnfree ? true,
          allowAliases ? true,
          allowHomeManager ? true,
          extraArgs ? { },
          extraPkgConfig ? { },
          extraPkgAttrs ? { },
        }:
        let
          isDarwin = builtins.match ".*darwin" system != null;
          specialArgs = {
            inherit
              flake
              paths
              ;
          } // extraArgs;
          pkgs =
            let
              mkPkgs =
                fromInput:
                import fromInput {
                  inherit system;
                  config = {
                    inherit allowUnfree allowAliases;
                  } // extraPkgConfig;
                };
              nixpkgs = if repo == "stable" then nixpkgs-stable else nixpkgs-unstable;
              lib = if allowHomeManager then nixpkgs.lib // homeManager.lib else nixpkgs.lib;
              defaultPkgs = mkPkgs nixpkgs;
              unstablePkgs = mkPkgs nixpkgs-unstable;
              stablePkgs = mkPkgs nixpkgs-stable;
            in
            defaultPkgs.extend (
              final: prev:
              {
                stable = stablePkgs;
                unstable = unstablePkgs;
                inherit lib;
              }
              // extraPkgAttrs
            );
          lib = pkgs.lib;
          modules =
            [ mods.core ]
            ++ (
              if allowHomeManager then
                with mods.home;
                [
                  forAll
                  (if isDarwin then forDarwin else forNixos)
                ]
              else
                [ ]
            )
            ++ [
              {
                #TODO:  DOTS.hosts.${name}.enable = true;
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
              modules
              specialArgs
              ;
          }
        else
          lib.nixosSystem {
            inherit
              system
              pkgs
              lib
              modules
              specialArgs
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
      # homeConfigurations = {
      #   craole = mkHome {
      #     name = "craole";
      #   };
      # };
    };
}
