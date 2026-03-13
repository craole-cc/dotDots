{
  _,
  src,
  ...
}: let
  __doc = ''
    Input Source Resolution

    Parses the raw flake to extract, normalize, and categorize its inputs.
    It maps arbitrarily named external flake inputs to a canonical internal
    format to ensure downstream derivations are predictable.
  '';

  __exports = {
    internal = {inherit resolveInputs sourceInput;};
    external = {inherit resolveInputs sourceInput;};
  };

  inherit (_.attrsets.resolution) byPaths;
  inherit (_.filesystem.resolution) getFlake;

  /**
  Resolves, normalizes, and categorizes flake inputs.

  Loads the current flake and maps inconsistently named inputs
  (e.g., `nixosPackages`, `darwinNix`) to canonical internal names
  (`nixpkgs`, `nix-darwin`). Categorizes them into `core`
  (providing legacyPackages) and `home` (providing standard packages).

  # Args:
    self: An already evaluated flake.
    path: The filesystem path to the flake (defaults to `src`).

  # Returns:
    resolved: A merged set of all normalized inputs (`core // home`).
    raw: The unmodified `inputs` block from the original flake.
    core: Nixpkgs channels with built-in fallback chains.
    home: System builders, themes, editors, and other standard inputs.
    flake: The raw evaluated flake.
  */
  resolveInputs = {
    self ? {},
    path ? src,
  }: let
    #> Fetch the Flake
    flake = getFlake {inherit self path;};

    #> Ensure we grab the inputs from the evaluated flake if `self` was empty
    raw = flake.inputs or {};
    attrset = raw;

    #> Resolve Core Nixpkgs Channels (Sequential for safety)
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

    nixpkgs-stable = byPaths {
      inherit attrset;
      default = nixpkgs; #? Fallback chain
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs-24.05"]
        ["nixpkgs-24.11"]
        ["nixpkgs-25.05"]
        ["nixpkgs-25.11"]
      ];
    };

    nixpkgs-unstable = byPaths {
      inherit attrset;
      default = nixpkgs-stable; #? Fallback chain
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-beta"]
        ["betaNix"]
        ["nixpkgs-unstable"]
      ];
    };

    core = {
      inherit nixpkgs nixpkgs-stable nixpkgs-unstable;
    };

    #> Resolve Home and System Inputs
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

    resolved = core // home;
  in {inherit resolved raw core home flake;};

  /**
  Builds the registry source configuration attribute for a given input.

  Darwin modules expect `source`; NixOS expects `flake.source`. Returns
  an empty set if no source is provided to prevent evaluation errors.

  # Type
  ```nix
  sourceInput :: { host? :: AttrSet, input? :: any } -> AttrSet
  ```

  # Examples
  ```nix
  sourceInput { host = { class = "darwin"; }; input = inputs.nixpkgs; }
  # => { source = <nixpkgs-store-path>; }

  sourceInput { input = inputs.home-manager; }
  # => { flake = { source = <home-manager-store-path>; }; }
  ```
  */
  sourceInput = {
    host ? {},
    input ? null,
  }: let
    class = host.class or "nixos";
  in
    if input == null
    then {}
    else if class == "darwin"
    then {source = input;}
    else {flake = {source = input;};};
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
