let
  flake = rec {
    store = ./.;
    local = "/home/craole/.dots"; # TODO: Not portable
    nixos = "/Modules/nixos";
    modules = {
      store = store + nixos;
      local = local + nixos;
    };
  };
  paths = import (flake.modules.store + "/paths.nix") { inherit flake; };
  inherit (builtins) map attrNames readDir;
  inherit (paths.modules) parts;
in
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
    flakeParts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flakeCompat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flakeUtils.url = "github:numtide/flake-utils";
    # flakeUtilsPlus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flakeShell.url = "github:numtide/devshell";
    flakeFormatter.url = "github:numtide/treefmt-nix";

    flakeProcess.url = "github:Platonic-Systems/process-compose-flake";
    flakeService.url = "github:juspay/services-flake";
    flakeCI.url = "github:juspay/omnix";

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

  # outputs =
  #   inputs:
  #   with inputs;
  #   flakeParts.lib.mkFlake { inherit inputs; } {
  #     debug = true;
  #     systems = nixpkgs.lib.systems.flakeExposed;
  #     imports = [
  #       flakeProcess.flakeModule
  #     ];
  #     perSystem =
  #       { ... }:
  #       {
  #         process-compose."myservices" = {
  #           imports = [
  #             flakeService.processComposeModules.default
  #           ];
  #         };
  #       };
  #   };

  # outputs =
  #   {
  #     self,
  #     nixpkgs,
  #     ...
  #   }@inputs:
  # inputs.flakeUtils.lib.eachDefaultSystem (
  #   system:
  #   let
  #     flake = rec {
  #       store = ./.;
  #       local = "/home/craole/.dots"; # TODO: Not portable
  #       nixos = "/Modules/nixos";
  #       modules = {
  #         store = store + nixos;
  #         local = local + nixos;
  #       };
  #     };
  #     paths = import (flake.modules.store + "/paths.nix") { inherit flake; };

  #     mkConfig = import paths.libraries.mkConf {
  #       inherit self inputs paths;
  #     };
  #   in
  #   {
  #     devShells.default =
  #       let
  #         pkgs = import nixpkgs {
  #           inherit system;
  #           config.allowUnfree = true;
  #           overlays = with inputs; [ flakeShell.overlays.default ];
  #         };
  #         inherit (pkgs.devshell) mkShell importTOML;
  #       in
  #       mkShell {
  #         imports = with paths.devShells; [
  #           (importTOML dots)
  #           # (importTOML dev)
  #           # (importTOML media)
  #           # (importTOML env)
  #         ];
  #       };

  #     nixosConfigurations = {
  #       QBX = mkConfig "QBX" { };
  #       Preci = mkConfig "Preci" { };
  #       dbOOK = mkConfig "dbOOK" { };
  #     };

  #     #TODO: Create separate config directory for nix darwin systems since the config is drastically different
  #     # darwinConfigurations = {
  #     #   MBPoNine = mkDarwinConfig "MBPoNine" { };
  #     # };

  #     # TODO create mkHome for standalone home manager configs
  #     # homeConfigurations = mkHomeConfig "craole" { };
  #   }
  # );

  outputs =
    inputs@{ self, ... }:
    inputs.flakeParts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      # imports = map (fn: ./modules/flake-parts/${fn}) (attrNames (readDir ./modules/flake-parts));

      devshells = {
        default = paths.devShells.dots;
      };
      perSystem =
        { lib, system, ... }:
        {
          # Make our overlay available to the devShell
          # "Flake parts does not yet come with an endorsed module that initializes the pkgs argument.""
          # So we must do this manually; https://flake.parts/overlays#consuming-an-overlay
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = lib.attrValues self.overlays;
            config.allowUnfree = true;
          };
        };

      # https://omnix.page/om/ci.html
      flake.om.ci.default.ROOT = {
        dir = ".";
        steps.flake-check.enable = false; # Doesn't make sense to check nixos config on darwin!
        steps.custom = { };
      };
    };
}
