{
  _,
  lib,
  src,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';
  inherit (_.attrsets.resolution) byPaths;

  getSystem = pkgs: pkgs.stdenv.hostPlatform.system;

  mkInputs = {inputs}: {
    nixpkgs = byPaths {
      attrset = inputs;
      default = "nixpkgs";
      paths = [
        ["nixosCore"]
        ["nixPackages"]
        ["nixosPackages"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
      ];
    };

    nixpkgs-stable = byPaths {
      attrset = inputs;
      default = "nixpkgs-stable";
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-unstable = byPaths {
      attrset = inputs;
      default = "nixpkgs-unstable";
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixpkgs"]
      ];
    };

    nix-darwin = byPaths {
      attrset = inputs;
      default = "nix-darwin";
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
      ];
    };

    home-manager = byPaths {
      attrset = inputs;
      default = "home-manager";
      paths = [
        ["nixHomeManager"]
        ["nixosHome"]
        ["nixHome"]
        ["homeManager"]
        ["home"]
      ];
    };

    fresh-editor = byPaths {
      attrset = inputs;
      default = "fresh-editor";
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
      ];
    };

    helix = byPaths {
      attrset = inputs;
      default = "helix";
      paths = [
        ["helix-editor"]
        ["hx"]
        ["helixEditor"]
        ["editorHelix"]
        ["editorHX"]
      ];
    };

    noctalia-shell = byPaths {
      attrset = inputs;
      default = "noctalia-shell";
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
      ];
    };

    dank-material-shell = byPaths {
      attrset = inputs;
      default = "dank-material-shell";
      paths = [
        ["shellDankMaterial"]
        ["shellDank"]
        ["dank-material"]
        ["dank"]
        ["dms"]
      ];
    };

    nvf = byPaths {
      attrset = inputs;
      default = "nvf";
      paths = [
        ["editorNeovim"]
        ["neovim"]
        ["nvim"]
        ["neovimFlake"]
        ["neoVim"]
      ];
    };

    plasma = byPaths {
      attrset = inputs;
      default = "plasma";
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
      ];
    };

    treefmt = byPaths {
      attrset = inputs;
      default = "treefmt";
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
      ];
    };

    vscode-insiders = byPaths {
      attrset = inputs;
      default = "vscode-insiders";
      paths = [
        ["vscode"]
        ["code"]
        ["code-insiders"]
        ["vsc"]
        ["VSCode"]
        ["editorVscode"]
        ["editorVscodeInsiders"]
        ["vscode-insiders-nix"]
      ];
    };

    zen-browser = byPaths {
      attrset = inputs;
      default = "zen-browser";
      paths = [
        ["browserZen"]
        ["firefoxZen"]
        ["zen"]
        ["zenBrowser"]
        ["zenFirefox"]
        ["twilight"]
      ];
    };
  };

  mkPackages = {inputs}: {
    #~@ Core
    nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages or {};
    nixpkgs-unstable = inputs.nixpkgs-unstable.legacyPackages or {};
    home-manager = inputs.home-manager.packages or {};

    #~@ Applications
    dank-material-shell = inputs.dank-material-shell.packages or {};
    fresh-editor = inputs.fresh-editor.packages or {};
    helix = inputs.helix.packages or {};
    noctalia-shell = inputs.noctalia-shell.packages or {};
    nvf = inputs.nvf.packages or {};
    plasma = inputs.plasma.packages or {};
    treefmt = inputs.treefmt.packages or {};
    vscode-insiders = inputs.vscode-insiders.packages or {};
    zen-browser = inputs.zen-browser.packages or {};
  };

  mkOverlays = {
    nixpkgs-stable,
    nixpkgs-unstable,
    packages,
    config,
  }: [
    #~@ Stable
    (final: prev: {
      fromStable = import nixpkgs-stable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Unstable
    (final: prev: {
      fromUnstable = import nixpkgs-unstable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Flake inputs
    #? Flattened packages (higher priority)
    (final: prev:
      filterAttrsRecursive (name: value: value != null) (
        mapAttrs' (_name: pkgsSet: {
          name = _name;
          value = pkgsSet.${getSystem prev}.${"default"} or null;
        })
        packages
      ))

    #? Categorized (lower priority, for browsing)
    (final: prev: {
      fromInputs =
        mapAttrs (
          _: pkgs: pkgs.${getSystem prev} or {}
        )
        packages;
    })
  ];
  mkModules = {
    inputs,
    class ? "nixos",
  }: {
    core =
      (
        if class == "darwin"
        then [inputs.home-manager.darwinModules.home-manager]
        else [inputs.home-manager.nixosModules.home-manager]
      )
      ++ optionals
      (inputs ? nvf)
      [inputs.nvf.homeManagerModules.default or {}]
      ++ [];
    home = [];
  };
  # homeModules = {path ? src}: let
  #   inputs = norm path;
  # in
  #   []
  #   ++ optionals
  #   (inputs ? dank-material-shell)
  #   [inputs.dank-material-shell.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? fresh-editor)
  #   [inputs.fresh-editor.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? helix)
  #   [inputs.helix.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? noctalia-shell)
  #   [inputs.noctalia-shell.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? nvf)
  #   [inputs.nvf.homeManagerModules.default or {}]
  #   ++ optionals
  #   (inputs ? plasma)
  #   [inputs.plasma.homeModules.plasma-manager or {}]
  #   ++ optionals
  #   (inputs ? treefmt)
  #   [inputs.treefmt.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? vscode-insiders)
  #   [inputs.vscode-insiders.homeModules.default or {}]
  #   ++ optionals
  #   (inputs ? zen-browser)
  #   [inputs.zen-browser.homeModules.default or {}]
  #   ++ [];

  exports = {inherit mkInputs mkPackages mkOverlays;};
in
  exports // {_rootAliases = exports;}
