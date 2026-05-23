{
  _,
  src,
  ...
}: let
  meta = let
    doc = ''
      Input Source Resolution

      Parses the raw flake to extract, normalize, and categorize its inputs.
      It maps arbitrarily named external flake inputs to a canonical internal
      format to ensure downstream derivations are predictable.

      Also provides lock file predicates for querying persisted input metadata
      purely, without evaluating the flake.
    '';

    exports = let
      internal = let
        functions = {inherit normalize mkSource;};
        aliases = {
          normalizeInputs = normalize;
          sourceInput = mkSource;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        resolveInputs = normalize;
        mkInputSource = mkSource;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.debug.assertions) withContext;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.filesystem.resolution) getFlake;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.predicates) isAttrs isPath isString;

  /**
  Builds the registry source configuration attribute for a given input.

  Darwin modules expect `source`; NixOS expects `flake.source`. Returns
  an empty set if no source is provided to prevent evaluation errors.

  # Type
  ```nix
  mkSource:: { host? :: AttrSet, input? :: any } -> AttrSet

  # Examples
  mkSource{ host = { class = "darwin"; }; input = inputs.nixpkgs; }
  => { source = <nixpkgs-store-path>; }

  mkSource{ input = inputs.home-manager; }
  => { flake = { source = <home-manager-store-path>; }; }
  */
  mkSource = {
    host ? {},
    input ? null,
    ...
  }:
    optionalAttrs (isNotEmpty input)
    (
      if (host.class or "nixos") == "darwin"
      then {source = input;}
      else {flake.source = input;}
    );

  differentRev = left: right:
    isNotEmpty left
    && isNotEmpty right
    && ((left.rev or null) != (right.rev or null));

  /**
   Resolve a one-level flake input by trying the provided aliases in order.

   The lookup is case-insensitive. It lowercases the actual keys in `inputs`,
   lowercases each candidate name, then delegates ordered resolution to `byPaths`.

   This catches case-only variations such as:
   ```nix
   ai
   AI
   llm
   LLM
   editorVscode
   editorVSCode
   EDITORVSCODE
  ```

   Semantic aliases must still be listed explicitly. For example,
   nixPackagesStable, nixpkgsStable, and nixpkgs-stable are different
   names, not merely case variants.

   # Dependencies
   - attrsets.resolution.byPaths
   - strings.transformation.toLowerCase

   # Type
   byNames :: {
     inputs :: AttrSet,
     names :: [string],
     default? :: a
   } -> a

   # Examples
   byNames {
     inputs.AI = "llm-agents";
     names = ["ai" "llm" "llm-agents"];
     default = null;
   }
   # => "llm-agents"

   byNames {
     inputs.editorVSCode = "vscode-insiders";
     names = ["editorVscode" "vscode" "code"];
     default = null;
   }
   # => "vscode-insiders"

   byNames {
     inputs.nixpkgs-stable = "stable";
     names = ["nixPackagesStable" "nixpkgsStable" "nixpkgs-stable"];
     default = null;
   }
   # => "stable"
  */
  byNames = {
    inputs,
    names,
    default ? {},
  }:
    byPaths {
      attrset = listToAttrs (
        map
        (name: {
          name = toLowerCase name;
          value = inputs.${name};
        })
        (attrNames inputs)
      );
      paths = map (name: [(toLowerCase name)]) names;
      inherit default;
    };

  # TODO: Add dependencies and Examples to the doc
  /**
  Normalizes inputs of a flake

  # Input
  flake: An already evaluated flake. (optional)
  path: The filesystem path to the flake (defaults to `src`).
  inputs: Raw flake inputs. Defaults to `(defaults to current flake inputs)`.

  # Returns
  raw: The unmodified `inputs` block from the original flake.
  core: Nixpkgs channels with built-in fallback chains.
  home: System builders, themes, editors, and other standard inputs.
  plus each normalized input at the top level.

  # Type
  ```nix
  tryNames :: { names :: [string], default? :: a } -> a
  ```
  */
  normalize = value: let
    args =
      if isAttrs value && (value ? flake || value ? path || value ? inputs)
      then value
      else if isAttrs value
      then {inputs = value;}
      else if isPath value || isString value
      then {path = value;}
      else
        assert withContext {
          name = "normalize";
          context = "validating normalize value";
          assertion = false;
          message = "expected `value` to be an inputs attrset, path, or string";
        }; null;

    flake = args.flake or null;
    path = args.path or (args.src or null);
    inputs = args.inputs or (getFlake {inherit flake path;}).inputs or {};

    tryNames = names: byNames {inherit inputs names;};

    core = let
      explicit = byNames {
        inherit inputs;
        default = inputs.nixpkgs or {};
        names = [
          "nixosCore"
          "nixPkgs"
          "nixPackages"
          "nixosPackages"
          "nixpkgs"
        ];
      };

      stable = tryNames [
        "nixPackagesStable"
        "nixosPackagesStable"
        "stableNixpkgs"
        "nixpkgsStable"
        "nixpkgs-stable"
        "nixpkgs_24_05"
        "nixpkgs_24_11"
        "nixpkgs_25_05"
        "nixpkgs_25_11"
        "nixpkgs-24.05"
        "nixpkgs-24.11"
        "nixpkgs-25.05"
        "nixpkgs-25.11"
      ];

      unstable = tryNames [
        "nixPackagesUnstable"
        "nixosPackagesUnstable"
        "unstableNixpkgs"
        "nixpkgsUnstable"
        "nixpkgs-beta"
        "betaNix"
        "nixpkgs-unstable"
      ];

      nixpkgs =
        if isNotEmpty explicit
        then explicit
        else if isNotEmpty unstable
        then unstable
        else if isNotEmpty stable
        then stable
        else throw "We should never have gotten to this point. nixpkgs is required";
    in (
      {inherit nixpkgs;}
      // optionalAttrs (differentRev unstable nixpkgs) {nixpkgs-unstable = unstable;}
      // optionalAttrs (differentRev stable nixpkgs) {nixpkgs-stable = stable;}
    );

    home = {
      nix-darwin = tryNames [
        "darwin"
        "nixDarwin"
        "darwinNix"
        "nix-darwin"
      ];

      home-manager = tryNames [
        "nixHomeManager"
        "nixosHome"
        "nixHome"
        "homeManager"
        "home"
        "home-manager"
      ];

      age = tryNames [
        "secretsManager"
        "secretManager"
        "age"
        "agenix"
      ];

      catppuccin = tryNames [
        "styleCatppuccin"
        "catppuccinStyle"
        "catppuccin"
      ];

      chaotic = tryNames [
        "nixChaotic"
        "kernelChaotic"
        "chaoticKernel"
        "chaoticNyx"
        "chaotic"
      ];

      stylix = tryNames [
        "nixStyle"
        "styleManager"
        "stylix"
      ];

      caelestia = tryNames [
        "shellCaelestia"
        "caelestiaShell"
        "caelestia-shell"
        "caelestia"
      ];

      dank-material-shell = tryNames [
        "shellDankMaterial"
        "dankMaterialShell"
        "shellDank"
        "dank-material"
        "dank-material-shell"
        "dank"
        "dms"
      ];

      dms-plugin-registry = tryNames [
        "shellDankMaterialPlugins"
        "dankMaterialShellPlugins"
        "shellDankPlugins"
        "dankMaterialPlugins"
        "dank-plugins"
        "dank-plugin-registry"
        "dms-plugins"
        "dmsp"
      ];

      fresh-editor = tryNames [
        "fresh"
        "freshEditor"
        "editorFresh"
        "fresh-editor"
      ];

      helix = tryNames [
        "helix-editor"
        "helixEditor"
        "editorHelix"
        "editorHX"
        "hx"
        "helix"
      ];

      llm-agents = tryNames [
        "ai"
        "aiAgents"
        "ai-agents"
        "llm"
        "llmAgents"
        "llm-agents"
      ];

      noctalia-shell = tryNames [
        "shellNoctalia"
        "noctaliaShell"
        "noctalia-dev"
        "noctalia"
        "noctalia-shell"
      ];

      nvf = tryNames [
        "editorNeovim"
        "neovim"
        "nvim"
        "neovimFlake"
        "neoVim"
        "nvf"
      ];

      plasma = tryNames [
        "shellPlasma"
        "plasma-manager"
        "plasmaManager"
        "kde"
        "plasma"
      ];

      quickshell = tryNames [
        "shellQuick"
        "quickShell"
        "qtshell"
        "qmlshell"
        "quick"
        "quickshell"
      ];

      treefmt = tryNames [
        "treeFormatter"
        "treefmtNix"
        "fmtree"
        "treefmt-nix"
        "treefmt"
      ];

      typix = tryNames [
        "docTypix"
        "typst"
        "typ"
        "typix"
      ];

      vscode-insiders = tryNames [
        "vscode"
        "vscodeInsiders"
        "vsCode"
        "vsCodeInsiders"
        "code"
        "code-insiders"
        "vsc"
        "editorVSCode"
        "editorVscode"
        "editorVscodeInsiders"
        "vscode-insiders-nix"
        "vscode-insiders"
      ];

      nix-vscode-extensions = tryNames [
        "editorVSCodeExtensions"
        "editorVSCodeMarketplace"
        "editorVscodeMarketplace"
        "vscodeMarketplace"
        "vscode-marketplace"
        "vscodeExtensions"
        "vscode-extensions"
        "nix-vscode-extensions"
      ];

      zen-browser = tryNames [
        "browserZen"
        "firefoxZen"
        "zen"
        "zenBrowser"
        "zenFirefox"
        "twilight"
        "zen-browser"
      ];
    };
  in
    {raw = inputs;} // core // home;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
