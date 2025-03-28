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
    inputs@{
      nixpkgs,
      flakeParts,
      ...
    }:
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
        {
          config,
          pkgs,
          ...
        }:
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
