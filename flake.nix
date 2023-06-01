{
  description = "My NixOS configuration";

  nixConfig = {
    extra-substituters = [ "https://cache.m7.rs" ];
    extra-trusted-public-keys = [ "cache.m7.rs:kszZ/NSwE/TjhOcPPQ16IuUiuRSisdiIwhKZCxguaWg=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:mic92/sops-nix";
    hydra.url = "github:nixos/hydra";
    hyprland.url = "github:hyprwm/hyprland";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

      mkNixos = modules: nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = { inherit inputs outputs; };
      };
      mkHome = modules: pkgs: home-manager.lib.homeManagerConfiguration {
        inherit modules pkgs;
        extraSpecialArgs = { inherit inputs outputs; };
      };
    in
    {
      nixosModules = import ./Global/Modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      templates = import ./templates;

      overlays = import ./overlays { inherit inputs outputs; };
      hydraJobs = import ./hydra.nix { inherit inputs outputs; };

      packages = forEachPkgs (pkgs: (import ./pkgs { inherit pkgs; }) // {
        neovim = let
          homeCfg = mkHome [ ./home/misterio/generic.nix ] pkgs;
        in pkgs.writeShellScriptBin "nvim" ''
          ${homeCfg.config.programs.neovim.finalPackage}/bin/nvim \
          -u ${homeCfg.config.xdg.configFile."nvim/init.lua".source} \
          "$@"
        '';
      });
      devShells = forEachPkgs (pkgs: import ./shell.nix { inherit pkgs; });
      formatter = forEachPkgs (pkgs: pkgs.nixpkgs-fmt);

      wallpapers = import ./home/misterio/wallpapers;

      nixosConfigurations = {
        # Desktops
        atlas = mkNixos [ ./hosts/atlas ];
        maia = mkNixos [ ./hosts/maia ];
        # Laptops
        pleione = mkNixos [ ./hosts/pleione ];
        electra = mkNixos [ ./hosts/electra ];
        # Servers
        alcyone = mkNixos [ ./hosts/alcyone ]; # Vultr VM (critical stuff)
        merope = mkNixos [ ./hosts/merope ]; # Raspberry Pi (media)
        celaeno = mkNixos [ ./hosts/celaeno ]; # Free Oracle VM (builds)
      };

      homeConfigurations = {
        # Desktops
        "misterio@atlas" = mkHome [ ./home/misterio/atlas.nix ] nixpkgs.legacyPackages."x86_64-linux";
        "misterio@maia" = mkHome [ ./home/misterio/maia.nix ] nixpkgs.legacyPackages."x86_64-linux";
        # Laptops
        "misterio@pleione" = mkHome [ ./home/misterio/pleione.nix ] nixpkgs.legacyPackages."x86_64-linux";
        "misterio@electra" = mkHome [ ./home/misterio/electra.nix ] nixpkgs.legacyPackages."x86_64-linux";
        # Servers
        "misterio@alcyone" = mkHome [ ./home/misterio/alcyone.nix ] nixpkgs.legacyPackages."x86_64-linux";
        "misterio@merope" = mkHome [ ./home/misterio/merope.nix ] nixpkgs.legacyPackages."aarch64-linux";
        "misterio@celaeno" = mkHome [ ./home/misterio/celaeno.nix ] nixpkgs.legacyPackages."aarch64-linux";

        # Portable minimum configuration
        "misterio@generic" = mkHome [ ./home/misterio/generic.nix ] nixpkgs.legacyPackages."x86_64-linux";
      };
    };
}
