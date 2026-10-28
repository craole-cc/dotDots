{_, ...}: let
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
          resolveInputs = normalize;
          mkInputSource = mkSource;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        resolveInputs = normalize;
        mkInputSource = mkSource;
      };
    in {
      inherit internal external;
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.sources.predicates) lockFileHas;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.transformation) toLowerCase pipe;
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
    optionalAttrs (isNotEmpty input) (
      if (host.class or "nixos") == "darwin"
      then {source = input;}
      else {flake.source = input;}
    );

  differentRev = left: right: isNotEmpty left && isNotEmpty right && ((left.rev or null) != (right.rev or null));

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

    When the resolved value is an attribute set (e.g. a flake), the actual
    matched key from `inputs` — original casing preserved — is appended as
    `name`. Values resolved to `default` (i.e. none of `names` matched) are
    never tagged, since no lookup actually succeeded.

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
      inputs.secretsManager = someFlake;
      names = ["secretManager" "age" "secretsManager" "agenix"];
      default = null;
    }
    # => someFlake // { name = "secretsManager"; }

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
  }: let
    keys = attrNames inputs;
    paths = map (name: [(toLowerCase name)]) names;

    lowered = listToAttrs (
      map (name: {
        name = toLowerCase name;
        value = inputs.${name};
      })
      keys
    );

    originals = listToAttrs (
      map (name: {
        name = toLowerCase name;
        value = name;
      })
      keys
    );

    value = byPaths {
      attrset = lowered;
      inherit paths default;
    };
    found = byPaths {
      attrset = originals;
      inherit paths;
      default = null;
    };
  in
    if isNotEmpty value && found != null && isAttrs value
    then value // {name = found;}
    else value;

  # TODO: Add dependencies and Examples to the doc
  /**
  Normalises the inputs of a flake.

  Accepts a raw inputs attrset, an attrset with `flake`, `path` or `inputs`,
  or a path/string (stored as `path`). Only the `inputs` form is currently
  read; `flake` and `path` are accepted but not yet resolved.

  # Input
  value: One of
    - an inputs attrset
    - `{ inputs, flake?, path? }`
    - a path or string

  # Returns
  raw: The unmodified `inputs` block from the original flake.
  caches: Binary cache definitions (`sub`, `key`, `when`) for resolved inputs.
  selection: Which inputs to read packages from.
    core = { attrs = "legacyPackages"; names = [...]; }
    home = { attrs = "packages"; names = [...]; }
  nixpkgs, nixpkgs-stable?, nixpkgs-unstable?: Resolved channels. The stable
    and unstable entries appear only when their rev differs from `nixpkgs`.
  Plus each resolved home input at the top level, keyed by its canonical name.
  Inputs that don't resolve are empty.

  # Type
  ```nix
  normalize :: AttrSet | Path | String -> AttrSet
  ```
  */
  normalize = value: let
    args =
      if
        isAttrs value
        && (value ? flake || value ? path || value ? inputs)
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

    # flake = args.flake or null;
    # path = args.home or (args.path or (args.src or null));
    # inputs = args.inputs or((getFlake {inherit flake path;}).inputs or {});
    inherit (args) inputs;
    raw = inputs;

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
    in
      {inherit nixpkgs;}
      // optionalAttrs (differentRev unstable nixpkgs) {nixpkgs-unstable = unstable;}
      // optionalAttrs (differentRev stable nixpkgs) {nixpkgs-stable = stable;};

    specs = {
      nix-darwin = {
        names = [
          "darwin"
          "nixDarwin"
          "darwinNix"
          "nix-darwin"
        ];
      };

      niri = {
        names = ["niri"];
      };

      niri-float-sticky = {
        names = ["niriFloatSticky" "niri-float-sticky"];
      };

      home-manager = {
        names = [
          "nixHomeManager"
          "nixosHome"
          "nixHome"
          "homeManager"
          "home"
          "home-manager"
        ];
      };

      age = {
        names = [
          "secretsManager"
          "secretManager"
          "age"
          "agenix"
        ];
      };

      buuf-icons = {
        names = [
          "buuf-nestort"
          "buufIcons"
          "buuf"
          "buuf-icons"
        ];
      };

      catppuccin = {
        names = [
          "styleCatppuccin"
          "catppuccinStyle"
          "catppuccin"
        ];
      };

      chaotic = {
        names = [
          "nixChaotic"
          "kernelChaotic"
          "chaoticKernel"
          "chaoticNyx"
          "chaotic"
        ];
        cache = {
          sub = "https://nyx-cache.chaotic.cx/";
          key = "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=";
          when = {
            kernel ? null,
            pkgs,
            ...
          }:
            kernel != null && (hasInfix "cachyos" kernel || hasAttr kernel pkgs);
        };
      };

      caelestia = {
        names = [
          "shellCaelestia"
          "caelestiaShell"
          "caelestia-shell"
          "caelestia"
        ];
      };

      codex = {
        names = [
          "codex-community"
          "openai-codex"
          "codex-cli"
          "codex"
        ];
      };
      codex-plugins = {
        names = [
          "codex-plugins"
          "openai-plugins"
        ];
      };
      codex-skills = {
        names = [
          "codex-skills"
          "openai-skills"
        ];
      };

      dank-greeter = {
        names = [
          "greeterDankMaterial"
          "dank-material-greeter"
          "dms-greeter"
          "greeterDankMaterial"
          "dank-greeter"
        ];
      };

      dank-material-shell = {
        names = [
          "shellDankMaterial"
          "dankMaterialShell"
          "shellDank"
          "dank-material"
          "dank-material-shell"
          "dank"
          "dms"
        ];
      };

      dms-plugin-registry = {
        names = [
          "dms-plugin-registry"
          "shellDankMaterialPlugins"
          "dankMaterialShellPlugins"
          "shellDankPlugins"
          "dankMaterialPlugins"
          "dank-plugins"
          "dank-plugin-registry"
          "dms-plugins"
          "dmsp"
        ];
      };

      fresh-editor = {
        names = [
          "fresh"
          "freshEditor"
          "editorFresh"
          "fresh-editor"
        ];
      };

      helix = {
        names = [
          "helix-editor"
          "helixEditor"
          "editorHelix"
          "editorHX"
          "hx"
          "helix"
        ];
      };

      llm-agents = {
        names = [
          "ai"
          "aiAgents"
          "ai-agents"
          "llm"
          "llmAgents"
          "llm-agents"
        ];
      };

      hermes-agent = {
        names = [
          "hermes"
          "hermes-agent"
          "nous"
        ];
      };

      rust-overlay = {
        names = [
          "rustOverlay"
          "rust-overlay"
          "oxalica"
        ];
      };

      noctalia-shell = {
        names = [
          "shellNoctalia"
          "noctaliaShell"
          "noctalia-dev"
          "noctalia"
          "noctalia-shell"
        ];
      };

      nvf = {
        names = [
          "editorNeovim"
          "neovim"
          "nvim"
          "neovimFlake"
          "neoVim"
          "nvf"
        ];
      };

      plasma = {
        names = [
          "shellPlasma"
          "plasma-manager"
          "plasmaManager"
          "kde"
          "plasma"
        ];
      };

      quickshell = {
        names = [
          "shellQuick"
          "quickShell"
          "qtshell"
          "qmlshell"
          "quick"
          "quickshell"
        ];
      };

      stylix = {
        names = [
          "nixStyle"
          "styleManager"
          "stylix"
        ];
      };

      treefmt = {
        names = [
          "treeFormatter"
          "treefmtNix"
          "fmtree"
          "treefmt-nix"
          "treefmt"
        ];
      };

      typix = {
        names = [
          "docTypix"
          "editorTypix"
          "typst"
          "typ"
          "typix"
        ];
      };

      vscode-insiders = {
        names = [
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
      };

      nix-vscode-extensions = {
        names = [
          "editorVSCodeExtensions"
          "editorVSCodeMarketplace"
          "editorVscodeMarketplace"
          "vscodeMarketplace"
          "vscode-marketplace"
          "vscodeExtensions"
          "vscode-extensions"
          "nix-vscode-extensions"
        ];
      };

      warp-terminal = {
        names = [
          "warp"
          "warp-preview"
          "warpPreview"
          "terminalWarp"
          "warp-terminal-experimental"
          "warpTerm"
          "warpTerminal"
          "warp-terminal"
        ];
      };

      zen-browser = {
        names = [
          "browserZen"
          "firefoxZen"
          "zen"
          "zenBrowser"
          "zenFirefox"
          "twilight"
          "zen-browser"
        ];
      };
    };

    home = mapAttrs (_: spec: tryNames spec.names) specs;

    selection = {
      core = {
        attrs = "legacyPackages";
        names = attrNames core;
      };
      home = {
        attrs = "packages";
        names = attrNames (filterAttrs (_: isNotEmpty) home);
      };
    };

    caches =
      (pipe specs [
        (filterAttrs (name: spec: spec ? cache && isNotEmpty home.${name}))
        (mapAttrs (_: spec: spec.cache))
      ])
      // {
        numtide = {
          when = {path ? null, ...}:
            lockFileHas {
              inherit path;
              field = "owner";
              value = "numtide";
            };
          sub = "https://cache.numtide.com";
          key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
        };
      };
  in
    {inherit raw caches selection;} // core // home;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
