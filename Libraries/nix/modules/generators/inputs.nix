{_, ...}: let
  inherit (_.attrsets.resolution) byPaths;

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

    catppuccin = byPaths {
      attrset = inputs;
      default = "catppuccin";
      paths = [
        ["styleCatppuccin"]
        ["catppuccinStyle"]
      ];
    };

    chaotic = byPaths {
      attrset = inputs;
      default = "chaotic";
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
      ];
    };

    stylix = byPaths {
      attrset = inputs;
      default = "stylix";
      paths = [
        ["nixStyle"]
        ["styleManager"]
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

    # fresh-editor = byPaths {
    #   attrset = inputs;
    #   default = "fresh-editor";
    #   paths = [
    #     ["fresh"]
    #     ["freshEditor"]
    #     ["editorFresh"]
    #   ];
    # };

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

    caelestia = byPaths {
      attrset = inputs;
      default = "caelestia";
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
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

    noctalia-shell = byPaths {
      attrset = inputs;
      default = "noctalia-shell";
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
      ];
    };

    quickshell = byPaths {
      attrset = inputs;
      default = "quickshell";
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
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

    typix = byPaths {
      attrset = inputs;
      default = "typix";
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
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

  exports = {inherit mkInputs;};
in
  exports // {_rootAliases = exports;}
