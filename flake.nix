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
      paths =
        let
          flake = {
            local = "/home/craole/Documents/dotfiles";
            store = ./.;
          };
          names = {
            modules = "/Configuration/apps/nixos";
            scripts = "/Bin";
            libraries = "/libraries";
            mkCore = "/helpers/makeCoreConfig.nix";
          };
          scripts = {
            local = flake.local + names.scripts;
            store = flake.store + names.scripts;
          };
          modules = {
            local = flake.local + names.modules;
            store = flake.store + names.modules;
          };
          libraries = {
            local = modules.local + names.libraries;
            store = modules.store + names.libraries;
            mkCore = libraries.local + names.mkCore;
          };
        in
        {
          inherit
            flake
            names
            scripts
            modules
            libraries
            ;
        };
      args = {
        inherit paths;
        flake = self;
      };
      mods = {
        environment = {
          variables = with paths; {
            DOTS = flake.local;
            DOTS_BIN = scripts.local;
            DOTS_NIX = modules.local;
          };
          shellAliases = {
            Flake = ''pushd ${paths.flake.local} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
          };
          pathsToLink =
            let
              bin = paths.scripts.local;
            in
            [
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
        };
      };
      init =
        {
          name,
          system,
          preferredRepo ? "unstable",
          allowUnfree ? true,
          allowAliases ? true,
          allowHomeManager ? true,
          enableDots ? false,
          extraPkgConfig ? { },
          extraPkgAttrs ? { },
        }:
        import paths.libraries.mkCore {
          inherit
            name
            system
            preferredRepo
            allowUnfree
            allowAliases
            allowHomeManager
            enableDots
            extraPkgConfig
            extraPkgAttrs
            ;
          inherit (inputs)
            nixosStable
            nixosUnstable
            homeManager
            nixDarwin
            ;
          inherit args mods;
          path = paths.modules.store;
        };
    in
    {
      nixosConfigurations = {
        preci = init {
          name = "preci";
          system = "x86_64-linux";
        };

        # preci = mkCore {
        #   name = "preci";
        #   system = "x86_64-linux";
        # };
        # dbook = mkCore {
        #   name = "dbook";
        #   system = "x86_64-linux";
        # };
      };

      # darwinConfigurations = {
      #   MBPoNine = mkCore {
      #     name = "MBPoNine";
      #     system = "x86_64-darwin";
      #   };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = {
      #   craole = mkHome {
      #     name = "craole";
      #   };
      # };
    };
}
