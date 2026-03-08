{_, ...}: let
  inherit (_.attrsets.resolution) byPaths;

  resolvedFlake = _.attrsets.resolution.flake {};
  rawInputs = resolvedFlake.inputs;

  resolvedInputs = {
    nixpkgs = byPaths {
      attrsets = rawInputs;
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
      attrsets = rawInputs;
      default = "nixpkgs-stable";
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-unstable = byPaths {
      attrsets = rawInputs;
      default = "nixpkgs-unstable";
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixpkgs"]
      ];
    };

    nix-darwin = byPaths {
      attrsets = rawInputs;
      default = "nix-darwin";
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
      ];
    };

    home-manager = byPaths {
      attrsets = rawInputs;
      default = "home-manager";
      paths = [
        ["nixHomeManager"]
        ["nixosHome"]
        ["nixHome"]
        ["homeManager"]
        ["home"]
      ];
    };

    catppuccin = byPaths {
      attrsets = rawInputs;
      default = "catppuccin";
      paths = [
        ["styleCatppuccin"]
        ["catppuccinStyle"]
      ];
    };

    chaotic = byPaths {
      attrsets = rawInputs;
      default = "chaotic";
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
      ];
    };

    fresh-editor = byPaths {
      attrsets = rawInputs;
      default = "fresh-editor";
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
      ];
    };

    stylix = byPaths {
      attrsets = rawInputs;
      default = "stylix";
      paths = [
        ["nixStyle"]
        ["styleManager"]
        ["darwinNix"]
      ];
    };

    helix = byPaths {
      attrsets = rawInputs;
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
      attrsets = rawInputs;
      default = "caelestia";
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
      ];
    };
    dank-material-shell = byPaths {
      attrsets = rawInputs;
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
      attrsets = rawInputs;
      default = "noctalia-shell";
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
      ];
    };

    quickshell = byPaths {
      attrsets = rawInputs;
      default = "quickshell";
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
      ];
    };

    nvf = byPaths {
      attrsets = rawInputs;
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
      attrsets = rawInputs;
      default = "plasma";
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
      ];
    };

    treefmt = byPaths {
      attrsets = rawInputs;
      default = "treefmt";
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
      ];
    };

    typix = byPaths {
      attrsets = rawInputs;
      default = "typix";
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
      ];
    };

    vscode-insiders = byPaths {
      attrsets = rawInputs;
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
      attrsets = rawInputs;
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

  exports = {
    inherit
      resolvedInputs
      resolvedFlake
      rawInputs
      ;
    inputs = resolvedInputs;
    flake = resolvedFlake;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        resolvedInputs
        resolvedFlake
        rawInputs
        ;
    };
  }
