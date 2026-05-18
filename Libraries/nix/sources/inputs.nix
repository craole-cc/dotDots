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

    Also provides lock file predicates for querying persisted input metadata
    purely, without evaluating the flake.
  '';
  functions = {inherit resolveInputs sourceInput;};
  __exports = {
    internal = functions;
    external = functions;
  };

  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.filesystem.resolution) getFlake;
  inherit (_.lists.predicates) any;
  inherit (_.attrsets.transformation) attrValues;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.predicates) fromJSON;

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
    ...
  }:
    optionalAttrs (isEmpty input)
    (
      if  (host.class or "nixos") == "darwin"
      then {source = input;}
      else {flake.source = input;}
    );
  # sourceInput = {
  #   host ? {},
  #   input ? null,
  # }: let
  #   class = host.class or "nixos";
  # in
  #   optionalAttrs (input == null) (
  #     if (class == "darwin")
  #     then {source = input;}
  #     else {flake.source = input;}
  #   );

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
    flake ? {},
    path ? src,
  }: let
    #> Fetch the Flake
    flake' = getFlake {inherit flake path;};

    #> Ensure we grab the inputs from the evaluated flake if `self` was empty
    raw = flake'.inputs or {};
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
      default = nixpkgs; # ? Fallback chain
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
      default = nixpkgs-stable; # ? Fallback chain
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-beta"]
        ["betaNix"]
        ["nixpkgs-unstable"]
      ];
    };

    core = {inherit nixpkgs nixpkgs-stable nixpkgs-unstable;};

    #> Resolve Home and System Inputs
    home = {
      nix-darwin = byPaths {
        inherit attrset;
        paths = [
          ["darwin"]
          ["nixDarwin"]
          ["darwinNix"]
          ["nix-darwin"]
        ];
      };

      home-manager = byPaths {
        inherit attrset;
        paths = [
          ["nixHomeManager"]
          ["nixosHome"]
          ["nixHome"]
          ["homeManager"]
          ["home"]
          ["home-manager"]
        ];
      };

      age = byPaths {
        inherit attrset;
        paths = [
          ["secretsManager"]
          ["age"]
          ["agenix"]
        ];
      };

      catppuccin = byPaths {
        inherit attrset;
        paths = [
          ["styleCatppuccin"]
          ["catppuccinStyle"]
          ["catppuccin"]
        ];
      };

      chaotic = byPaths {
        inherit attrset;
        paths = [
          ["nixChaotic"]
          ["kernelChaotic"]
          ["chaoticKernel"]
          ["chaotic"]
        ];
      };

      stylix = byPaths {
        inherit attrset;
        paths = [
          ["nixStyle"]
          ["styleManager"]
          ["stylix"]
        ];
      };

      caelestia = byPaths {
        inherit attrset;
        paths = [
          ["shellCaelestia"]
          ["caelestia-shell"]
          ["caelestia"]
        ];
      };

      dank-material-shell = byPaths {
        inherit attrset;
        paths = [
          ["shellDankMaterial"]
          ["shellDank"]
          ["dank-material"]
          ["dank"]
          ["dms"]
          ["dank-material-shell"]
        ];
      };

      dms-plugin-registry = byPaths {
        inherit attrset;
        paths = [
          ["shellDankMaterialPlugins"]
          ["shellDankPlugins"]
          ["dank-plugins"]
          ["dank-plugin-registry"]
          ["dms-plugins"]
          ["dmsp"]
          ["dank-plugin-registry"]
        ];
      };

      fresh-editor = byPaths {
        inherit attrset;
        paths = [
          ["fresh"]
          ["freshEditor"]
          ["editorFresh"]
          ["fresh-editor"]
        ];
      };

      helix = byPaths {
        inherit attrset;
        paths = [
          ["helix-editor"]
          ["hx"]
          ["helixEditor"]
          ["editorHelix"]
          ["editorHX"]
          ["helix"]
        ];
      };

      llm-agents = byPaths {
        inherit attrset;
        paths = [
          ["llm"]
          ["aiAgents"]
          ["ai-agents"]
          ["llm-agents"]
        ];
      };

      noctalia-shell = byPaths {
        inherit attrset;
        paths = [
          ["shellNoctalia"]
          ["noctalia-dev"]
          ["noctalia"]
          ["noctalia-shell"]
        ];
      };

      nvf = byPaths {
        inherit attrset;
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
        paths = [
          ["treeFormatter"]
          ["fmtree"]
          ["treefmt-nix"]
          ["treefmt"]
        ];
      };

      typix = byPaths {
        inherit attrset;
        paths = [
          ["docTypix"]
          ["typst"]
          ["typ"]
          ["typix"]
        ];
      };

      vscode-insiders = byPaths {
        inherit attrset;
        paths = [
          ["vscode"]
          ["code"]
          ["code-insiders"]
          ["vsc"]
          ["VSCode"]
          ["editorVSCode"]
          ["editorVscode"]
          ["editorVscodeInsiders"]
          ["vscode-insiders-nix"]
          ["vscode-insiders"]
        ];
      };

      nix-vscode-extensions = byPaths {
        inherit attrset;
        paths = [
          ["editorVSCodeExtensions"]
          ["editorVSCodeMarketplace"]
          ["editorVscodeMarketplace"]
          ["vscode-marketplace"]
          ["vscode-extensions"]
          ["nix-vscode-extensions"]
        ];
      };

      zen-browser = byPaths {
        inherit attrset;
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
  in {
    inherit
      resolved
      raw
      core
      home
      ;
    flake = flake';
  };
in
  __exports.internal
  // {
    inherit __doc;
    __rootAliases = __exports.external;
  }
