{
  description = "NixOS Configuration";
  inputs = {
    #/> Nix Packages <\
    nixpkgs =
      #| Standard Binaries
      {
        # url = "github:NixOS/nixpkgs/release-22.11"; #| Stable - 22.11
        url = "github:NixOS/nixpkgs/nixos-unstable"; # | Unstable
        # url = "github:nixos/nixpkgs/master"; #| Master
        # url = "github:nixos/nixpkgs/nixos-unstable-small"; #|Minimal
      };

    #/> NixOS Utilities <\
    nixos-hardware =
      #| Hardware Configuration
      {
        url = "github:nixos/nixos-hardware";
      };
    nixos-generators =
      #| System Images
      {
        url = "github:nix-community/nixos-generators";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    templates =
      #| NixOS Templates
      {
        url = "github:NixOS/templates";
      };

    #/> System Utilities <\
    darwin =
      #| MacOS
      {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    flake-utils =
      #| Flake Utils
      {
        url = "github:numtide/flake-utils";
      };
    flake-compat =
      #| Flake Compression
      {
        url = "github:edolstra/flake-compat";
        flake = false;
      };
    home-manager =
      #| User Environment Management
      {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        utils.follows = "flake-utils";
      };
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    ragenix =
      #| Age-encrypted Key Management
      {
        url = "github:yaxitech/ragenix";
        inputs.flake-utils.follows = "flake-utils";
        inputs.nixpkgs.follows = "nixpkgs";
      };

    #/> Development <\
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # /> Inteface <\
    # wayland =
    #   #| Wayland
    #   {
    #     url = "github:nix-community/nixpkgs-wayland";
    #     inputs.nixpkgs.follows = "nixpkgs";
    #   };
    # hyprland =
    #   #| Hyprland Window Manager
    #   {
    #     url = "github:hyprwm/Hyprland";
    #   };
    # hyprland-contrib =
    #   #| Hyprland Extras
    #   {
    #     url = "github:hyprwm/contrib";
    #     inputs.nixpkgs.follows = "nixpkgs";
    #   };
    # eww =
    #   #| EWW
    #   {
    #     url = "github:elkowar/eww";
    #     inputs.nixpkgs.follows = "nixpkgs";
    #   };
    # kmonad =
    #   #| Keyboard Management
    #   {
    #     url = "github:kmonad/kmonad?dir=nix";
    #     inputs.nixpkgs.follows = "nixpkgs";
    #   };

    # #/> Applications <\
    # firefox = {
    #   url = "github:colemickens/flake-firefox-nightly";
    # };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    {
      # hosts = import ./modules/hosts.nix;
      # deploy = import ./modules/deploy.nix inputs;
      overlays = import ./modules/overlays.nix inputs;
      darwinConfigurations = import ./modules/darwin.nix inputs;
      homeConfigurations = import ./modules/home-manager.nix inputs;
      nixosConfigurations = import ./modules/nixos.nix inputs;
    }
    //
      flake-utils.lib.eachSystem
        [
          "aarch64-linux"
          "x86_64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ]
        (localSystem: {
          checks = import ./modules/checks.nix inputs localSystem;
          # devShells.default = import ./modules/devshells.nix inputs localSystem;
          devShells.${localSystem}.default = import ./modules/devshells.nix inputs localSystem;
          packages =
            let
              hostDrvs = import ./modules/derivations.nix inputs localSystem;
              default =
                if builtins.hasAttr "${localSystem}" hostDrvs then
                  { default = self.packages.${localSystem}.${localSystem}; }
                else
                  { };
            in
            hostDrvs // default;
          pkgs = import nixpkgs {
            inherit localSystem;
            overlays = [ self.overlays.default ];
            config = {
              allowUnfree = true;
              allowAliases = true;
            };
          };
        });
}
