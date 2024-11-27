{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixosHardware = {
      url = "github:NixOS/nixos-hardware";
    };
    systems = {
      url = "github:nix-systems/default-linux";
    };
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed = {
      url = "github:Craole/nixed";
    };
    redyFonts = {
      url = "github:redyf/font-flake";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      nixDarwin,
      homeManager,
      ...
    }:
    let
      # lib = nixpkgs.lib // homeManager.lib // nixDarwin.lib;
      pkgsFor = system: repo: inputs."${repo}".legacyPackages.${system};

      dot = "/home/craole/Documents/dotfiles";
      mod = "/Configuration/apps/nixos";
      bin = dot + "/Bin";
      variables = {
        DOTS = dot;
        DOTS_BIN = bin;
        DOTS_NIX = dot + mod;
      };
      shellAliases = {
        Flake = ''pushd ${dot} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
      };
      pathsToLink = [
        (bin + "/base")
        (bin + "/core")
        (bin + "/import")
        (bin + "/interface")
        (bin + "/misc")
        (bin + "/packages")
        (bin + "/project")
        (bin + "/tasks")
        (bin + "/template")
        (bin + "/utility")
      ];
      modulesCore = ./. + mod;
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
      paths = {
        inherit
          dot
          mod
          bin
          ;
      };
      flake = self;
      packages =
        {
          system ? "x86_64-linux",
          allowUnfree ? true,
        }:
        with inputs;
        {
          stable = inputs.nixpkgs-stable.legacyPackages.${system};
          unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
          # unstable = pkgsFor system nixpkgs-unstable;
          # stable = pkgsFor system nixpkgs-stable;
          # unstable = pkgsFor system nixpkgs-unstable;
        };
      libraries = system: pkgs_repo: pkgs_repo // homeManager.lib;
    in
    {
      nixosConfigurations = {
        preci =
          let
            system = "x86_64-linux";
            packs = packages { inherit system; };
            pkgs = packs.unstable;
            lib = libraries system pkgs;
          in
          # pkgs = nixpkgs.legacyPackages.${system};
          # packs = {
          #   default = pkgsFor system "nixpkgs";
          #   stable = pkgsFor system "nixpkgsStable";
          #   unstable = pkgsFor system "nixpkgsUnstable";
          # };
          lib.nixosSystem {
            inherit system pkgs;
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
