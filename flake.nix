{
  description = "My NixOS configuration";

  nixConfig = {
    extra-substituters = ["https://cache.m7.rs"];
    extra-trusted-public-keys = ["cache.m7.rs:kszZ/NSwE/TjhOcPPQ16IuUiuRSisdiIwhKZCxguaWg="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware";
    impermanence.url = "github:nix-community/impermanence";
    nix-colors.url = "github:misterio77/nix-colors";
    sops-nix.url = "github:mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    hydra.url = "github:nixos/hydra";
    hyprland.url = "github:hyprwm/hyprland";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forEachSystem = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

    mkNixos = modules:
      nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = {inherit inputs outputs;};
      };
    mkHome = modules: pkgs:
      home-manager.lib.homeManagerConfiguration {
        inherit modules pkgs;
        extraSpecialArgs = {inherit inputs outputs;};
      };
  in {
    nixosModules = import ./Modules/nixos;
    homeManagerModules = import ./Modules/home-manager;
    templates = import ./Templates;
    overlays = import ./Middleware {inherit inputs outputs;};
    hydraJobs = import ./Admin/Hydra/default.nix {inherit inputs outputs;};

    packages = forEachPkgs (pkgs:
      (import ./Packages {inherit pkgs;})
      // {
        neovim = let
          homeCfg = mkHome [./Home/craole/clients/generic.nix] pkgs;
        in
          pkgs.writeShellScriptBin "nvim" ''
            ${homeCfg.config.programs.neovim.finalPackage}/bin/nvim \
            -u ${homeCfg.config.xdg.configFile."nvim/init.lua".source} \
            "$@"
          '';
      });
    devShells = forEachPkgs (pkgs: import ./Admin/Flake/shell.nix {inherit pkgs;});
    formatter = forEachPkgs (pkgs: pkgs.nixpkgs-fmt);
    wallpapers = import ./Home/craole/tools/desktop/wallpaper;

    nixosConfigurations = {
      #/> Desktop <\#
      dellberto = mkNixos [./Clients/dellberto];

      #/> Laptop <\#
      a3k = mkNixos [./Clients/a3k];
      delle = mkNixos [./Clients/delle];

      #/> Server <\#
      raspi = mkNixos [./Clients/raspi]; # Raspberry Pi (media)
    };

    homeConfigurations = {
      #/> Base <\#
      "craole@generic" =
        mkHome [./Home/craole/clients/generic.nix]
        nixpkgs.legacyPackages."x86_64-linux";

      #/> Desktop <\#
      "craole@dellberto" =
        mkHome [./Home/craole/clients/dellberto.nix]
        nixpkgs.legacyPackages."x86_64-linux";

      #/> Laptop <\#
      "craole@a3k" =
        mkHome [./Home/craole/clients/a3k.nix]
        nixpkgs.legacyPackages."x86_64-linux";
      "craole@delle" =
        mkHome [./Home/craole/clients/delle.nix]
        nixpkgs.legacyPackages."x86_64-linux";

      #/> Server <\#
      "craole@raspi" =
        mkHome [./Home/craole/clients/raspi.nix]
        nixpkgs.legacyPackages."aarch64-linux";
    };
  };
}
