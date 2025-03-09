{
  description = "DOTS - The NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flakeParts.url = "github:hercules-ci/flake-parts";

    homeManager.url = "github:nix-community/home-manager";
    devshell.url = "github:numtide/devshell";
    devenv.url = "github:cachix/devenv";
    treefmt.url = "github:numtide/treefmt-nix";
    missionControl.url = "github:Platonic-Systems/mission-control";

    nixed.url = "github:Craole/nixed";
  };

  outputs =
    inputs@{ nixpkgs, flakeParts, ... }:
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
        inherit inputs paths;
      };
    in
    flakeParts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = with inputs; [
        devshell.flakeModule
        devenv.flakeModule
        homeManager.flakeModules.home-manager
        missionControl.flakeModule
        treefmt.flakeModule
      ];
      flake = {
        # Put your original flake attributes here.
      };
      perSystem =
        { config, pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
          mission-control.scripts = {
            fmt = {
              description = "Format the source tree";
              exec = config.treefmt.build.wrapper;
              category = "Dev Tools";
            };
          };

          packages.default = pkgs.hello;

          devenv.shells.default = {
            name = "dots";
            env.GREET = "Welcome";
            # https://devenv.sh/reference/options/
            packages = [ config.packages.default ];

            enterShell = ''
              hello
            '';
          };

          # devshells.default = {
          #   env = [
          #     {
          #       name = "HTTP_PORT";
          #       value = 8080;
          #     }
          #   ];
          #   commands = [
          #     {
          #       help = "print hello";
          #       name = "hello";
          #       command = "echo hello";
          #     }
          #   ];
          #   packages = [
          #     pkgs.cowsay
          #   ];
          # };
          # devShells =
          #   let
          #     inherit (pkgs.devshell) mkShell importTOML;
          #     inherit (paths.devShells)
          #       dots
          #       dev
          #       media
          #       env
          #       ;
          #   in
          #   {
          #     default = mkShell {
          #       imports = [
          #         (importTOML dots)
          #         # (importTOML dev)
          #         # (importTOML media)
          #         # (importTOML env)
          #       ];
          #     };
          #   };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
