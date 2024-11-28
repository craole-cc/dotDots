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
    systems.url = "github:nix-systems/default-linux";
    nixed.url = "github:Craole/nixed";
    # redyFonts = {
    #   url = "github:redyf/font-flake";
    # };
  };
  outputs =
    inputs@{ self, ... }:
    let
      flake = self;
      paths = {
        dot = "/home/craole/Documents/dotfiles";
        mod = "/Configuration/apps/nixos";
        bin = "/Bin";
      };
      variables = with paths; {
        DOTS = dot;
        DOTS_BIN = dot + bin;
        DOTS_NIX = dot + mod;
      };
      shellAliases = {
        Flake = ''pushd ${paths.dot} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
      };
      pathsToLink = with paths; [
        (dot + bin + "/base")
        (dot + bin + "/core")
        (dot + bin + "/import")
        (dot + bin + "/interface")
        (dot + bin + "/misc")
        (dot + bin + "/packages")
        (dot + bin + "/project")
        (dot + bin + "/tasks")
        (dot + bin + "/template")
        (dot + bin + "/utility")
      ];
      modulesCore = ./. + paths.mod;
      modulesHome = {
        home-manager = {
          backupFileExtension = "BaC";
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
      modulesNixos = [
        modulesCore
        modulesHome
        homeManager.nixosModules.home-manager
      ];
      modulesDarwin = [
        modulesCore
        modulesHome
        homeManager.darwinModules.home-manager
      ];
      packages =
        {
          system,
          allowUnfree ? true,
          includeDarwin ? false,
        }:
        with inputs;
        {
          stable = import nixosStable {
            inherit system;
            config = {
              inherit allowUnfree;
            };
          };
          unstable = import nixosUnstable {
            inherit system;
            config = {
              inherit allowUnfree;
            };
          };
          libraries =
            let
              libs = nixosUnstable.lib // homeManager.lib;
            in
            if includeDarwin then libs // nixDarwin.lib else libs;
        };
    in
    {
      nixosConfigurations = {
        preci =
          let
            system = "x86_64-linux";
            packs = packages { inherit system; };
            pkgs = packs.unstable;
            lib = libraries;
          in
          lib.nixosSystem {
            inherit system pkgs lib;
            modules = modulesNixos ++ [
              {
                environment = {
                  inherit variables shellAliases pathsToLink;
                  systemPackages = [ ];
                };
                # DOTS.hosts.Preci.enable = true;
              }
            ];
            specialArgs = {
              inherit
                flake
                paths
                packs
                ;
            };
          };

        dbook =
          let
            system = "x86_64-linux";
            packs = packages { inherit system; };
            pkgs = packs.unstable;
            lib = libraries system pkgs;
          in
          lib.nixosSystem {
            system = "x86_64-linux";
            modules = modulesNixos ++ [
              {
                # DOTS.hosts.DBook.enable = true;
              }
            ];
            # modules = [ (hostModules + "/dbook") ] ++ modulesNixos;
          };
      };

      darwinConfigurations = {
        MBPoNine =
          let
            system = "x86_64-linux";
            packs = packages { inherit system; };
            pkgs = packs.unstable;
            lib = libraries system pkgs // nixDarwin.lib;
          in
          lib.darwinSystem {
            system = "x86_64-darwin";
            modules = modulesDarwin ++ [ { DOTS.hosts.MBPoNine.enable = true; } ];
          };
      };
    };
}
