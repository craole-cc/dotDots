{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosStable.url = "nixpkgs/nixos-24.05";
    nixosHardware.url = "github:NixOS/nixos-hardware";
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixUtils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # utils.follows = "nixUtils";
      };
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # flake-utils.follows = "nixUtils";
      };
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
    { self, ... }@inputs:
    let
      # pkgs = self.pkgs.x86_64-linux.nixpkgs;
      # mkApp = inputs.nixUtils.lib.mkApp;
      paths = import ./base.paths.nix;
      mkConfig = import ./base/mkConfig.nix {
        inherit self inputs paths;
      };
      # mkConfig =
      #   name: extraArgs:
      #   let
      #     host =
      #       let
      #         inherit (inputs.nixpkgs.lib.lists) foldl' filter;
      #         confCommon = import (paths.core.configurations.hosts + "/common");
      #         confSystem = import (paths.core.configurations.hosts + "/${name}");
      #         enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
      #         userConfigs = foldl' (
      #           acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
      #         ) { } enabledUsers;
      #       in
      #       {
      #         inherit name userConfigs;
      #       }
      #       // confCommon
      #       // confSystem
      #       // extraArgs;
      #     specialModules =
      #       let
      #         inherit (host) desktop;
      #         core =
      #           (with paths.core; [
      #             libraries
      #             modules
      #             options
      #           ])
      #           ++ (with inputs; [
      #             stylix.nixosModules.stylix
      #             nid.nixosModules.nix-index
      #           ]);
      #         home =
      #           with inputs;
      #           if desktop == "hyprland" then
      #             [ ]
      #           else if desktop == "plasma" then
      #             [ plasmaManager.homeManagerModules.plasma-manager ]
      #           else if desktop == "xfce" then
      #             [ ]
      #           else
      #             [ ];
      #       in
      #       {
      #         inherit core home;
      #       };

      #     specialArgs = {
      #       inherit self paths host;
      #       modules = specialModules;
      #       libraries = import paths.libraries.store; # TODO: Check on this
      #     };
      #   in
      #   import paths.libraries.mkCore {
      #     inherit (inputs)
      #       nixosStable
      #       nixosUnstable
      #       homeManager
      #       nixDarwin
      #       ;

      #     inherit (host)
      #       name
      #       # system
      #       ;

      #     inherit
      #       specialArgs
      #       specialModules
      #       ;

    in
    #     system = host.platform;
    #     preferredRepo = host.preferredRepo or "unstable";
    #     allowUnfree = host.allowUnfree or true;
    #     allowAliases = host.allowAliases or true;
    #     allowHomeManager = host.allowHomeManager or true;
    #     backupFileExtension = host.backupFileExtension or "BaC";
    #     extraPkgConfig = host.extraPkgConfig or { };
    #     extraPkgAttrs = host.extraPkgAttrs or { };
    #   };
    # inputs.nixUtils.lib.mkFlake {

    #   supportedSystems = [
    #     "aarch64-linux"
    #     "x86_64-linux"
    #   ];

    #   channelsConfig = {
    #     allowUnfree = true;
    #   };

    #   hosts = {
    #     QBX = {
    #       system = "x86_64-linux";
    #       modules = [ ./configurations/hosts/qbx ];
    #     };
    #   };
    # };
    {
      nixosConfigurations = {
        example = mkConfig "example" { };
        preci = mkConfig "preci" { };
        dbook = mkConfig "dbook" { };
      };

      #TODO: Create separate config directory for nix systems since the config is drastically different
      # darwinConfigurations = {
      #   MBPoNine = mkConfig "MBPoNine" { };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = mkConfig "craole" { };
    };
}
