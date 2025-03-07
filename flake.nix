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

    flakeUtils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    { self, nixpkgs, ... }@inputs:
    let
      paths =
        let
          flake = {
            local = "/home/craole/.dots";
            root = "/dots";
            store = ./.;
          };
          parts = {
            args = "/args";
            cfgs = "/configurations";
            env = "/environment";
            libs = "/libraries";
            mkCore = "/helpers/mkCoreConfig.nix";
            mkConf = "/helpers/mkConfig.nix";
            modules = "/Modules/nixos";
            mods = "/modules";
            opts = "/options";
            pkgs = "/packages";
            bin = "/Bin";
            svcs = "/services";
            ui = "/ui";
            uiCore = "/ui/core";
            uiHome = "/ui/home";
            hosts = parts.cfgs + "/hosts";
            users = parts.cfgs + "/users";
            scripts = "/scripts";
          };
          core = {
            default = modules.store;
            configurations = {
              hosts = core.default + parts.hosts;
              users = core.default + parts.users;
            };
            environment = core.default + parts.env;
            libraries = core.default + parts.libs;
            modules = core.default + parts.mods;
            options = core.default + parts.opts;
            packages = core.default + parts.pkgs;
            services = core.default + parts.svcs;
          };
          home = {
            default = modules.store + "/home";
            configurations = home.default + parts.cfgs;
            environment = home.default + parts.env;
            libraries = home.default + parts.libs;
            modules = home.default + parts.mods;
            options = home.default + parts.opts;
            packages = home.default + parts.pkgs;
            services = home.default + parts.svcs;
          };
          scripts = {
            global = flake.local + parts.bin;
            local = modules.store + parts.scripts;
            store = flake.store + parts.scripts;
            dots = modules.store + parts.scripts + "/init_dots";
          };
          modules = {
            local = flake.local + parts.modules;
            store = flake.store + parts.modules;
          };
          libraries = {
            local = modules.local + parts.libs;
            store = modules.store + parts.libs;
            mkCore = core.libraries + parts.mkCore;
            mkConf = core.libraries + parts.mkConf;
          };
        in
        {
          inherit
            flake
            core
            home
            scripts
            parts
            modules
            libraries
            ;
        };
      mkConfig = import paths.libraries.mkConf {
        inherit self inputs paths;
      };
    in
    {
      inherit paths;
      nixosConfigurations = {
        QBX = mkConfig "QBX" { };
        Preci = mkConfig "Preci" { };
        # dbook = mkConfig "dbook" { };
      };

      #TODO: Add devshell for temporary development environment
      devShells = inputs.flakeUtils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.hello
              pkgs.cowsay
            ];

            shellHook = ''
              echo "Welcome to the development shell!"
            '';
          };
        }
      );

      # devShells.default = pkgs.mkShell {
      #   inputsFrom = [ (import ./shell.nix { inherit pkgs; }) ];
      # };
      #      devShells = flake-utils.lib.eachDefaultSystem (system: let
      #     pkgs = import nixpkgs { inherit system; };
      #   in {
      #     default = pkgs.mkShell {
      #       buildInputs = [
      #         pkgs.hello  # Add packages you need in your dev shell
      #         pkgs.cowsay
      #       ];

      #       shellHook = ''
      #         echo "Welcome to the development shell!"
      #       '';
      #     };
      #   });
      # };

      #TODO: Create separate config directory for nix darwin systems since the config is drastically different
      # darwinConfigurations = {
      #   MBPoNine = mkDarwinConfig "MBPoNine" { };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = mkHomeConfig "craole" { };
    };
}
