{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.content.fallback) orDefault;
  inherit (_.content.empty) isNotEmpty;
  inherit (_.filesystem.predicates) pathExists;
  inherit (_.types.predicates) isAttrs;
  inherit (lib.strings) hasSuffix;

  exports = {
    internal = {
      inherit
        tryFlake
        mkFlake
        mkInputs
        mkNixPkgs
        ;
    };
    external = exports.internal;
  };

  tryFlake = path: let
    file = "/flake.nix";
    p = toString (
      if isNotEmpty path
      then path
      else src
    );
    resolvedPath =
      if hasSuffix file p && pathExists p
      then p
      else if pathExists (p + file)
      then p + file
      else null;
  in
    if resolvedPath != null
    then import resolvedPath
    else null;

  mkFlake = {
    flake ? null,
    path ? src,
  }:
    if isNull flake
    then
      orDefault {
        content = tryFlake path;
        default = throw "❌ '${toString path}' is not a valid flake path.";
      }
    else flake;

  mkInputs = {
    self ? {},
    path ? src,
  }: let
    /**
    The resolved flake attrset for the current project, obtained via
    `_.attrsets.resolution.flake {}`. Used as the root from which all inputs
    are derived.
    */
    flake = tryFlake {inherit self path;};

    /**
    The raw `inputs` attrset from the resolved flake, exactly as declared in
    `flake.nix`. All resolution in `coreInputs` and `homeInputs` is performed
    against this attrset.
    */
    raw = self.inputs or {};
    attrset = raw;

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

    /**
    Combined view of all resolved inputs (`coreInputs // homeInputs`).

    Use this when you need access to any input by canonical name and don't
    need to distinguish between `legacyPackages`-style and `packages`-style
    inputs.
    */
    resolved = core // home;
  in {inherit resolved raw core home flake;};

  /**
  Build the `nixpkgs` source attribute appropriate for the host class.

  Darwin uses `source`; NixOS uses `flake.source`. Resolves `root` from
  `inputs.nixpkgs` when not explicitly provided.

  # Type
  ```
  source :: { host? :: AttrSet, root? :: any, inputs? :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  mkNixPkgs { host.class = "darwin"; inputs.nixpkgs = nixpkgs; }
  # => { source = nixpkgs; }

  mkNixPkgs { inputs.nixpkgs = nixpkgs; }
  # => { flake.source = nixpkgs; }
  ```
  */
  mkNixPkgs = {
    class ? "nixos",
    inputs ? {},
    ...
  }: let
    root = inputs.nixpkgs or null;
  in
    if class == "darwin"
    then {source = root;}
    else {flake.source = root;};
in
  exports.internal // {_rootAliases = exports.external;}
