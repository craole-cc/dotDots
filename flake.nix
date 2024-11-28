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
    nixed.url = "github:Craole/nixed";
  };
  outputs =
    inputs@{
      self,
      nixosStable,
      nixosUnstable,
      homeManager,
      nixDarwin,
      ...
    }:
    let
      flake = self;
      paths =
        let
          flake = "/home/craole/Documents/dotfiles";
          conf = "/Configuration/apps/nixos";
          bin = flake + "/Bin";
          lib = conf + "/libraries";
        in
        {
          inherit
            flake
            conf
            lib
            bin
            ;
          mkCoreConfig = flake + lib + "/helpers/makeCoreConfig.nix";
        };
      variables = with paths; {
        DOTS = flake;
        DOTS_BIN = bin;
        DOTS_NIX = conf;
      };
      shellAliases = {
        Flake = ''pushd ${paths.flake} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
      };
      pathsToLink = with paths; [
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
    in
    {
      nixosConfigurations = {
        preci =
          let
            # enableDots = true;
            name = "preci";
            system = "x86_64-linux";
            configMods = {
              environment = {
                inherit variables shellAliases pathsToLink;
              };
            };
          in
          import paths.mkCoreConfig {
            inherit name system;
            inherit (inputs)
              nixosStable
              nixosUnstable
              homeManager
              nixDarwin
              ;
            configPath = ./. + paths.conf;
            configArgs = {
              inherit
                flake
                paths
                configMods
                ;
            };
          };

        # preci = mkCore {
        #   name = "preci";
        #   system = "x86_64-linux";
        # };
        # dbook = mkCore {
        #   name = "dbook";
        #   system = "x86_64-linux";
        # };
      };

      # darwinConfigurations = {
      #   MBPoNine = mkCore {
      #     name = "MBPoNine";
      #     system = "x86_64-darwin";
      #   };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = {
      #   craole = mkHome {
      #     name = "craole";
      #   };
      # };
    };
}
