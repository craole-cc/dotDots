{_, ...}: let
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.filesystem.paths) tryFlake;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;

  exports = {
    internal = {
      inherit
        core
        home
        resolved
        flake
        ;
      inputs = resolved;
      inputsRaw = raw;
    };
    external = {
      resolvedInputs = resolved;
      resolvedFlake = flake;
      coreInputs = core;
      homeInputs = home;
      rawInputs = raw;
    };
  };

  /**
  The resolved flake attrset for the current project, obtained via
  `_.attrsets.resolution.flake {}`. Used as the root from which all inputs
  are derived.
  */
  flake = tryFlake {};

  /**
  The raw `inputs` attrset from the resolved flake, exactly as declared in
  `flake.nix`. All resolution in `coreInputs` and `homeInputs` is performed
  against this attrset.
  */
  raw = flake.inputs;
  attrset = raw;

  /**
  Combined view of all resolved inputs (`coreInputs // homeInputs`).

  Use this when you need access to any input by canonical name and don't
  need to distinguish between `legacyPackages`-style and `packages`-style
  inputs.
  */
  resolved = core // home;

  /**
  Resolved nixpkgs inputs — the three channels that expose `legacyPackages`
  (per-system attrsets of every package in nixpkgs).

  These are accessed differently from all other inputs and drive the overlay
  system in `inputs/packages.nix`. Only `nixpkgs`, `nixpkgs-stable`, and
  `nixpkgs-unstable` belong here.

  The three variants form a deliberate fallback chain so that consumers always
  receive a usable package set even when not all channels are pinned:

    nixpkgs-unstable → nixpkgs-stable → nixpkgs → {}

  Cross-channel fallback is handled via `default`; each entry's `paths` covers
  only alternative *names* for that specific channel.
  */
  core = rec {
    /**
    Base nixpkgs input. Tries common alternative input names before falling
    back to an empty attrset. All other nixpkgs variants degrade to this.
    */
    nixpkgs = byPaths {
      inherit attrset;
      default = attrset.nixpkgs or {};
      paths = [
        ["nixosCore"]
        ["nixPackages"]
        ["nixosPackages"]
        ["nixpkgs"]
      ];
    };

    /**
    Stable nixpkgs channel. Falls back to resolved `nixpkgs` when absent.

    Covers common alternative names including versioned release pins
    (`nixpkgs-24.11`, `nixpkgs-25.05`, etc.). Arbitrary version names not
    listed here degrade to `nixpkgs` via `default`.
    */
    nixpkgs-stable = byPaths {
      inherit attrset;
      default = nixpkgs;
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        # Versioned release pins — NixOS YY.MM format
        ["nixpkgs-24.05"]
        ["nixpkgs-24.11"]
        ["nixpkgs-25.05"]
        ["nixpkgs-25.11"]
      ];
    };

    /**
    Unstable nixpkgs channel. Falls back to resolved `nixpkgs-stable` (which
    itself falls back to `nixpkgs`) giving the full chain:
    unstable → stable → nixpkgs → {}.
    */
    nixpkgs-unstable = byPaths {
      inherit attrset;
      default = nixpkgs-stable;
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-beta"]
        ["betaNix"]
        ["nixpkgs-unstable"]
      ];
    };
  };

  /**
  Resolved home and system inputs — everything that exposes `packages`
  (accessed via `inputs.<n>.packages.<system>`).

  Includes system builders (`nix-darwin`, `home-manager`), theming
  (`catppuccin`, `stylix`, `chaotic`), editors (`nvf`, `helix`,
  `fresh-editor`, `vscode-insiders`), shells (`caelestia`,
  `dank-material-shell`, `noctalia-shell`, `quickshell`, `plasma`),
  browsers (`zen-browser`), and dev tools (`treefmt`, `typix`).
  */
  home = {
    nix-darwin = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
        ["nix-darwin"]
      ];
    };

    home-manager = byPaths {
      inherit attrset;
      default = {};
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
      inherit attrset;
      default = {};
      paths = [
        ["styleCatppuccin"]
        ["catppuccinStyle"]
        ["catppuccin"]
      ];
    };

    chaotic = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
        ["chaotic"]
      ];
    };

    stylix = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["nixStyle"]
        ["styleManager"]
        ["stylix"]
      ];
    };

    caelestia = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
        ["caelestia"]
      ];
    };

    dank-material-shell = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["shellDankMaterial"]
        ["shellDank"]
        ["dank-material"]
        ["dank"]
        ["dms"]
        ["dank-material-shell"]
      ];
    };

    fresh-editor = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
        ["fresh-editor"]
      ];
    };

    helix = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["helix-editor"]
        ["hx"]
        ["helixEditor"]
        ["editorHelix"]
        ["editorHX"]
        ["helix"]
      ];
    };

    noctalia-shell = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
        ["noctalia-shell"]
      ];
    };

    nvf = byPaths {
      inherit attrset;
      default = {};
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
      inherit attrset;
      default = {};
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
        ["plasma"]
      ];
    };

    quickshell = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
        ["quickshell"]
      ];
    };

    treefmt = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
        ["treefmt"]
      ];
    };

    typix = byPaths {
      inherit attrset;
      default = {};
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
        ["typix"]
      ];
    };

    vscode-insiders = byPaths {
      inherit attrset;
      default = {};
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
      inherit attrset;
      default = {};
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
in
  exports.internal
  // {
    _rootAliases = exports.external;

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
          command = ''byPaths falls back when no path matches'';
          outcome = byPaths {
            attrset = {canonical = "fallback";};
            paths = [["noSuchKey"]];
            default = "fallback";
          };
        };
        prefersEarlierPath = mkTest {
          desired = "first";
          command = ''byPaths { paths = [["keyA"] ["keyB"]]; } prefers keyA'';
          outcome = byPaths {
            attrset = {
              keyA = "first";
              keyB = "second";
            };
            paths = [["keyA"] ["keyB"]];
            default = null;
          };
        };
        returnsDefaultWhenNothingMatches =
          mkTest' null
          (byPaths {
            attrset = {};
            paths = [["missing"] ["alsoMissing"]];
            default = null;
          });
        resolvesNestedPath = mkTest {
          desired = 1;
          command = ''byPaths { paths = [["missing"] ["foo" "bar"]]; } resolves foo.bar'';
          outcome = byPaths {
            attrset = {foo.bar = 1;};
            paths = [["missing"] ["foo" "bar"]];
            default = null;
          };
        };
      };
    };
  }
