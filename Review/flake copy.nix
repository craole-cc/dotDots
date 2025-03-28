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
    # systems = "";

    flakeParts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flakeCompat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flakeUtils.url = "github:numtide/flake-utils";
    # flakeUtilsPlus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flakeShell.url = "github:numtide/devshell";
    flakeFormatter.url = "github:numtide/treefmt-nix";

    dotsDev.url = "path:./Templates/dev";
    dotsMedia.url = "path:./Templates/media";
    nixed.url = "github:Craole/nixed";

    nid = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    {
      self,
      flakeParts,
      ...
    }@inputs:
    let
      # # Small tool to iterate over each systems
      # eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      # # Eval the treefmt modules from ./treefmt.nix
      # treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
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
            devShells = "/Modules/dev";
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
          devShells = rec {
            default = flake.store + parts.devShells;
            dots = default + "/dots.toml";
            dev = default + "/dev.toml";
            env = default + "/env.toml";
            media = default + "/media.toml";
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
            devShells
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
    flakeParts.lib.mkFlake {
      inherit self inputs;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # overlays = [
      #   flakeShell.overlays.default
      # ];

      # perSystem =
      #   { pkgs, system, ... }:
      #   {
      #     devShells = {
      #       default =
      #         let
      #           inherit (pkgs.devshell) mkShell importTOML;
      #           inherit (paths.devShells)
      #             dots
      #             dev
      #             media
      #             env
      #             ;
      #           shells =
      #             if system == "aarch64-linux" then
      #               [ (importTOML dots) ]
      #             else
      #               [
      #                 (importTOML dots)
      #                 (importTOML dev)
      #                 (importTOML media)
      #                 (importTOML env)
      #               ];
      #         in
      #         mkShell { imports = shells; };
      #     };
      #   };

      # devShells.default =
      #   let
      #     pkgs = import nixpkgs {
      #       inherit system;
      #       overlays = [ flakeShell.overlays.default ];
      #     };

      #     inherit (pkgs.devshell) mkShell importTOML;
      #   in
      #   mkShell {
      #     imports = with paths.devShells; [
      #       (importTOML dots)
      #       # (importTOML dev)
      #       # (importTOML media)
      #       # (importTOML env)
      #     ];
      #   };

      # formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      # checks = eachSystem (pkgs: {
      #   formatting = treefmtEval.${pkgs.system}.config.build.check self;
      # });
      nixosConfigurations = {
        QBX = mkConfig "QBX" { };
        Preci = mkConfig "Preci" { };
        # dbook = mkConfig "dbook" { };
      };

      #TODO: Create separate config directory for nix darwin systems since the config is drastically different
      # darwinConfigurations = {
      #   MBPoNine = mkDarwinConfig "MBPoNine" { };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = mkHomeConfig "craole" { };
    };
}
