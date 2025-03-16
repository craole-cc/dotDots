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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake Parts: https://flake.parts/
    flakeParts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flakeDocs.url = "github:srid/emanote";
    flakeShell.url = "github:numtide/devshell";
    flakeFormatter.url = "github:numtide/treefmt-nix";
    flakeProcess.url = "github:Platonic-Systems/process-compose-flake";
    flakeService.url = "github:juspay/services-flake";
    flakeCI.url = "github:juspay/omnix";

    # flakeCompat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    # flakeUtils.url = "github:numtide/flake-utils";
    # flakeUtilsPlus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    # dotsDev.url = "path:./Templates/dev";
    # dotsMedia.url = "path:./Templates/media";
    nixed.url = "github:Craole/nixed";

    nid = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # plasmaManager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";
  };

  outputs =
    inputs@{ self,... }:
    let
      paths = import ./paths.nix;
      flakePaths = paths;
      # mkConfig = import paths.libraries.mkConf {
      #   inherit inputs paths;
      # };

      # systems = nixpkgs.lib.systems.flakeExposed;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    inputs.flakeParts.lib.mkFlake { inherit self inputs; } {
      inherit systems;
      debug = true;
      # inherit systems;
      imports =
        with inputs;
        [
          # flakeDocs.flakeModule
          flakeShell.flakeModule
          flakeFormatter.flakeModule
        ]
        ++ (with flakePaths; [
          # paths.devshells
          # ./Modules/nixos/modules/devshells/default.nix
        ]);

      perSystem = {self, lib, system, ...}: {
        _module = {
          args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = lib.attrValues self.overlays;
            config.allowUnfree = true;
          };
          specialArgs = {inherit self flakePaths; };
        };
      };
      # perSystem =
      #   {
      #     pkgs,
      #     lib,
      #     system,
      #     ...
      #   }:
      #   {
      #     # "Flake parts does not yet come with an endorsed module that initializes the pkgs argument.""
      #     # So we must do this manually; https://flake.parts/overlays#consuming-an-overlay
      #     _module.args.pkgs = import inputs.nixpkgs {
      #       inherit system;
      #       overlays = lib.attrValues self.overlays;
      #       config.allowUnfree = true;
      #     };
      #     # devshells =
      #     #   let
      #     #     shells = with paths.devshells; {
      #     #       dots = import dots.nix { inherit pkgs paths; };
      #     #       media = import media.nix { inherit pkgs paths; };
      #     #     };
      #     #   in
      #     #   with shells;
      #     #   {
      #     #     default = dots;
      #     #     inherit dots media;
      #     #   };
      #     # treefmt = import ./Modules/nixos/modules/treefmt.nix { inherit pkgs; };
      #   };

      # https://omnix.page/om/ci.html
      # flake.om.ci.default.ROOT = {
      #   dir = ".";
      #   steps.flake-check.enable = false; # Doesn't make sense to check nixos config on darwin!
      #   steps.custom = { };
      # };
    };
}
