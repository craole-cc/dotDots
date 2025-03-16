{
  description = "NixOS Configuration Flake";

  inputs = {
    #| Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-unified.url = "github:srid/nixos-unified";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #| Software inputs
    github-nix-ci.url = "github:juspay/github-nix-ci";
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omnix.url = "github:juspay/omnix";
    hyprland.url = "github:hyprwm/Hyprland/v0.46.2";

    #| Neovim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Devshell
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      flake = false;
    };

    #| Templates
    nixed.url = "github:Craole/nixed";

    # nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixosUnstable.url = "nixpkgs/nixos-unstable";
    # nixosStable.url = "nixpkgs/nixos-24.11";
    # nixosHardware.url = "github:NixOS/nixos-hardware";
    # nixDarwin = {
    #   url = "github:LnL7/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # homeManager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Flake Parts: https://flake.parts/
    # flakeParts = {
    #   url = "github:hercules-ci/flake-parts";
    #   inputs.nixpkgs-lib.follows = "nixpkgs";
    # };
    # flakeUpdate.url = "github:srid/nixos-unified";
    # flakeDocs.url = "github:srid/emanote";
    # flakeShell.url = "github:numtide/devshell";
    # flakeFormatter.url = "github:numtide/treefmt-nix";
    # flakeProcess.url = "github:Platonic-Systems/process-compose-flake";
    # flakeService.url = "github:juspay/services-flake";
    # flakeCI.url = "github:juspay/omnix";
    # flakeHooks = {
    #   url = "github:cachix/git-hooks.nix";
    #   flake = false;
    # };

    # flakeCompat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    # flakeUtils.url = "github:numtide/flake-utils";
    # flakeUtilsPlus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    # dotsDev.url = "path:./Templates/dev";
    # dotsMedia.url = "path:./Templates/media";
    # nid = {
    #   url = "github:nix-community/nix-index-database";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    inputs@{ self, ... }:
    # systems = nixpkgs.lib.systems.flakeExposed;
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [./paths.nix];
        # let
        #   paths = import ./paths.nix;
        #   flakePaths = paths;
        #   inherit (flakePaths) parts;
        # in
        # mkConfig = import paths.libraries.mkConf {
        #   inherit inputs paths;
        # };
        # parts = ./Modules/nixos/components;
        # (with builtins; map (fn: parts/${fn}) (attrNames (readDir parts)));

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
