{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    listToAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
    ;
  inherit
    (lib.lists)
    concatMap
    concatLists
    elem
    filter
    toList
    unique
    ;
  inherit (lib.packages) getSystem mkPkgs;
  inherit (lib.shells) mkFormatting mkTools mkShells;
  inherit (lib.strings) concatNonEmpty toPascalCase isString toLower;
  inherit (lib.templates) deployTemplates;

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  isDisabled = value:
    value == null
    || value == false
    || value == {}
    || value == []
    || value == "";

  isEnabled = value: !isDisabled value;

  # ---------------------------------------------------------------------------
  # Normalizers
  # ---------------------------------------------------------------------------

  normalizeEditor = editor: let
    editorGroups = {
      helix      = ["helix" "hx"];
      neovim     = ["neovim" "nvim"];
      rust-rover = ["idea" "jetbrains" "rust-rover" "rustrover"];
      sublime    = ["sublime-text" "sublime"];
      vscode     = ["code" "cursor" "vscode-insiders" "vscode" "vscodium" "windsurf"];
      zed        = ["zed" "zeditor"];
    };
    knownEditors = concatLists (attrValues editorGroups);
  in
    if isDisabled editor
    then {enable = false; base = false; editors = [];}
    else if editor == true
    then {enable = true; base = true; editors = [];}
    else if isString editor && toLower editor == "all"
    then {enable = true; base = true; editors = knownEditors;}
    else let
      resolved = unique (
        filter (e: elem e knownEditors) (map toLower (toList editor))
      );
    in {
      enable = resolved != [];
      base   = resolved != [];
      editors = resolved;
    };

  normalizeFeature = defaults: value:
    if isDisabled value
    then defaults // {enable = false;}
    else if value == true
    then defaults // {enable = true;}
    else defaults // value // {enable = isEnabled (value.enable or true);};

  normalizeAi = value:
    if isDisabled value
    then {
      enable        = false;
      includeCodex  = false;
      includeClaude = false;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == "minimal"
    then {
      enable        = true;
      includeCodex  = true;
      includeClaude = false;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == true || value == "default"
    then {
      enable        = true;
      includeCodex  = true;
      includeClaude = true;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == "full"
    then {
      enable        = true;
      includeCodex  = true;
      includeClaude = true;
      includeHermes = true;
      includeOpenClaw = true;
    }
    else normalizeFeature {
      enable        = false;
      includeCodex  = false;
      includeClaude = false;
      includeHermes = false;
      includeOpenClaw = false;
    } value;

  normalizeVariant = raw: {
    base = normalizeFeature {
      enable      = true;
      includeMise = false;
    } (raw.base or true);

    ai = normalizeAi (raw.ai or null);

    rust = let
      base = normalizeFeature {
        enable           = false;
        includeToolchain = false;
      } (raw.rust or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeRust or false);};

    web = let
      base = normalizeFeature {
        enable          = false;
        includeDeno     = false;
        includePrettier = false;
        includeTrunk    = false;
      } (raw.web or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeWeb or false);};

    database = let
      base = normalizeFeature {
        enable          = false;
        includeMysql    = false;
        includePostgres = false;
        includeRedis    = false;
        includeSqlite   = false;
      } (raw.database or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeDatabase or false);};

    editor = normalizeEditor (raw.editor or null);
  };

  # ---------------------------------------------------------------------------
  # Tier definitions
  #
  # Each tier is a raw config attrset.  The caller's `config` is
  # recursiveUpdate'd on top so flake-level overrides propagate everywhere.
  # AI is set explicitly per tier; feature tiers leave AI off.
  # ---------------------------------------------------------------------------

  mkTierRaw = config: tier: recursiveUpdate tier config;
  mkTierVariants = config: let
    tier = mkTierRaw config;
  in {
    # --- Opinionated tiers ---------------------------------------------------
    minimal = tier {
      ai = "minimal";
    };

    default = tier {
      rust = true;
      ai   = "default";
    };

    full = tier {
      rust     = true;
      web      = true;
      database = true;
      ai       = "full";
    };

    # --- Feature tiers (AI off unless caller overrides) ----------------------
    rust = tier {
      rust = true;
    };

    rustWeb = tier {
      rust = true;
      web  = true;
    };

    rustDatabase = tier {
      rust     = true;
      database = true;
    };

    rustWebDatabase = tier {
      rust     = true;
      web      = true;
      database = true;
    };

    web = tier {
      web = true;
    };

    webDatabase = tier {
      web      = true;
      database = true;
    };

    database = tier {
      database = true;
    };
  };

  # Canonical editor group names used for With{Editor} shell names.
  editorGroupNames = ["helix" "neovim" "rust-rover" "sublime" "vscode" "zed"];

  # toPascalCase handles the hyphen: rust-rover → RustRover
  editorShellName = tierName: editorName:
    concatNonEmpty "" [tierName "With" (toPascalCase editorName)];

  # ---------------------------------------------------------------------------
  # Shell builder
  # ---------------------------------------------------------------------------

  mkEnvironment = {
    inputs,
    self,
    pkgs      ? mkPkgs {inherit inputs;},
    config    ? {},
    extraPackages ? [],
    extraEnv      ? {},
  }: let

    # Raw tier map — config overrides already baked in
    tierRaws = mkTierVariants config;

    # Normalized variant map — one per tier
    tierVariants = mapAttrs (_: normalizeVariant) tierRaws;

    # Build a shell spec from a normalized variant
    mkShellSpec = variant: let
      tools    = mkTools {inherit pkgs variant;};
      packages =
        []
        ++ (attrValues formatting.packages.${getSystem pkgs})
        ++ tools.packages
        ++ extraPackages;
      env      = {} // tools.env // extraEnv;
      shellHook = tools.shellHook;
    in {inherit packages env shellHook;};

    # formatting is variant-agnostic (driven by the default variant)
    formatting = mkFormatting {inherit inputs self;} tierVariants.default;

    # templates derivation for the default variant (exported for convenience)
    templates = deployTemplates {inherit pkgs; variant = tierVariants.default;};

    # --- Base shells (one per tier) ------------------------------------------
    baseShells = mapAttrs (_: v: mkShellSpec v) tierVariants;

    # --- Editor cross-product shells -----------------------------------------
    # Every tier × every editor group → {tierName}With{EditorName}
    editorShells = listToAttrs (
      concatMap
      (tierName:
        map
        (editorName: {
          name  = editorShellName tierName editorName;
          value = mkShellSpec (
            normalizeVariant (
              recursiveUpdate
              tierRaws.${tierName}
              {editor = editorName;}
            )
          );
        })
        editorGroupNames
      )
      (attrNames tierRaws)
    );

    # --- All shells combined --------------------------------------------------
    shells = baseShells // editorShells;

  in {
    inherit templates;
    inherit (formatting) formatter checks;
    devShells = mkShells {inherit inputs shells;};
  };

in {
  inherit
    mkEnvironment
    normalizeVariant
    normalizeFeature
    normalizeAi
    normalizeEditor
    ;
}
