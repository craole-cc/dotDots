{_, ...}: let
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;

  resolvedFlake = _.attrsets.resolution.flake {};
  rawInputs = resolvedFlake.inputs;

  resolvedInputs = {
    nixpkgs = byPaths {
      attrset = rawInputs;
      default = rawInputs.nixpkgs or {};
      paths = [
        ["nixosCore"]
        ["nixPackages"]
        ["nixosPackages"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-stable = byPaths {
      attrset = rawInputs;
      default = rawInputs.nixpkgs-stable or rawInputs.nixpkgs or {};
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-unstable = byPaths {
      attrset = rawInputs;
      default = rawInputs.nixpkgs-unstable or rawInputs.nixpkgs or {};
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixpkgs"]
      ];
    };

    nix-darwin = byPaths {
      attrset = rawInputs;
      default = rawInputs.nix-darwin or {};
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
        ["nix-darwin"]
      ];
    };

    home-manager = byPaths {
      attrset = rawInputs;
      default = rawInputs.home-manager or {};
      paths = [
        ["nixHomeManager"]
        ["nixosHome"]
        ["nixHome"]
        ["homeManager"]
        ["home"]
        ["home-manager"]
      ];
    };

    catppuccin = byPaths {
      attrset = rawInputs;
      default = rawInputs.catppuccin or {};
      paths = [
        ["styleCatppuccin"]
        ["catppuccinStyle"]
        ["catppuccin"]
      ];
    };

    chaotic = byPaths {
      attrset = rawInputs;
      default = rawInputs.chaotic or {};
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
        ["chaotic"]
      ];
    };

    fresh-editor = byPaths {
      attrset = rawInputs;
      default = rawInputs.fresh-editor or {};
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
        ["fresh-editor"]
      ];
    };

    stylix = byPaths {
      attrset = rawInputs;
      default = rawInputs.stylix or {};
      paths = [
        ["nixStyle"]
        ["styleManager"]
        ["stylix"]
      ];
    };

    helix = byPaths {
      attrset = rawInputs;
      default = rawInputs.helix or {};
      paths = [
        ["helix-editor"]
        ["hx"]
        ["helixEditor"]
        ["editorHelix"]
        ["editorHX"]
        ["helix"]
      ];
    };

    caelestia = byPaths {
      attrset = rawInputs;
      default = rawInputs.caelestia or {};
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
        ["caelestia"]
      ];
    };

    dank-material-shell = byPaths {
      attrset = rawInputs;
      default = rawInputs.dank-material-shell or {};
      paths = [
        ["shellDankMaterial"]
        ["shellDank"]
        ["dank-material"]
        ["dank"]
        ["dms"]
        ["dank-material-shell"]
      ];
    };

    noctalia-shell = byPaths {
      attrset = rawInputs;
      default = rawInputs.noctalia-shell or {};
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
        ["noctalia-shell"]
      ];
    };

    quickshell = byPaths {
      attrset = rawInputs;
      default = rawInputs.quickshell or {};
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
        ["quickshell"]
      ];
    };

    nvf = byPaths {
      attrset = rawInputs;
      default = rawInputs.nvf or {};
      paths = [
        ["editorNeovim"]
        ["neovim"]
        ["nvim"]
        ["neovimFlake"]
        ["neoVim"]
        ["nvf"]
      ];
    };

    plasma = byPaths {
      attrset = rawInputs;
      default = rawInputs.plasma or {};
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
        ["plasma"]
      ];
    };

    treefmt = byPaths {
      attrset = rawInputs;
      default = rawInputs.treefmt or {};
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
        ["treefmt"]
      ];
    };

    typix = byPaths {
      attrset = rawInputs;
      default = rawInputs.typix or {};
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
        ["typix"]
      ];
    };

    vscode-insiders = byPaths {
      attrset = rawInputs;
      default = rawInputs.vscode-insiders or {};
      paths = [
        ["vscode"]
        ["code"]
        ["code-insiders"]
        ["vsc"]
        ["VSCode"]
        ["editorVscode"]
        ["editorVscodeInsiders"]
        ["vscode-insiders-nix"]
        ["vscode-insiders"]
      ];
    };

    zen-browser = byPaths {
      attrset = rawInputs;
      default = rawInputs.zen-browser or {};
      paths = [
        ["browserZen"]
        ["firefoxZen"]
        ["zen"]
        ["zenBrowser"]
        ["zenFirefox"]
        ["twilight"]
        ["zen-browser"]
      ];
    };
  };

  exports = {
    inherit resolvedInputs resolvedFlake rawInputs;
    inputs = resolvedInputs;
    flake = resolvedFlake;
  };
in
  exports
  // {
    _rootAliases = {
      inherit (exports) resolvedInputs resolvedFlake rawInputs;
    };

    _tests = runTests {
      byPaths = {
        resolvesFirstMatchingPath = mkTest {
          desired = "found";
          command = ''byPaths { attrset = { aliasKey = "found"; }; paths = [["aliasKey"]]; default = null; }'';
          outcome = byPaths {
            attrset = {aliasKey = "found";};
            paths = [["aliasKey"]];
            default = null;
          };
        };
        fallsBackToDefault = mkTest {
          desired = "fallback";
          command = ''byPaths { attrset = { canonical = "fallback"; }; paths = [["noSuchKey"]]; default = "fallback"; }'';
          outcome = byPaths {
            attrset = {canonical = "fallback";};
            paths = [["noSuchKey"]];
            default = "fallback";
          };
        };
        prefersEarlierPath = mkTest {
          desired = "first";
          command = ''byPaths { attrset = { keyA = "first"; keyB = "second"; }; paths = [["keyA"] ["keyB"]]; default = null; }'';
          outcome = byPaths {
            attrset = {
              keyA = "first";
              keyB = "second";
            };
            paths = [["keyA"] ["keyB"]];
            default = null;
          };
        };
        returnsDefaultWhenNothingMatches = mkTest' null (byPaths {
          attrset = {};
          paths = [["missing"] ["alsoMissing"]];
          default = null;
        });
        resolvesNestedPath = mkTest {
          desired = 1;
          command = ''byPaths { attrset = { foo.bar = 1; }; paths = [["missing"] ["foo" "bar"]]; default = null; }'';
          outcome = byPaths {
            attrset = {foo.bar = 1;};
            paths = [["missing"] ["foo" "bar"]];
            default = null;
          };
        };
      };
    };
  }
