{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    isAttrs
    listToAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
    ;
  inherit
    (lib.lists)
    concatLists
    concatMap
    elem
    filter
    toList
    unique
    ;
  inherit (lib.shells) mkShell;
  inherit
    (lib.strings)
    concatNonEmpty
    isString
    optionalString
    toJSON
    toLower
    toUpper
    toPascalCase
    ;
  inherit (lib.trivial) hasAny isDisabled isEnabled isNotEmpty;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Core                                                      ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeCommon = value:
    normalizeFeature {
      kind = "core";
      name = "common";
      enable = true;
    }
    value;

  normalizeExtra = value: let
    default = {
      kind = "core";
      name = "extra";
      enable = false;
      includeMise = false;
      includeFetch = false;
      includeGitTools = false;
      includeFileTools = false;
      includeRustScript = false;
    };
  in
    if isEnabled value
    then
      default
      // {
        enable = true;
        includeMise = true;
        includeFetch = true;
        includeGitTools = true;
        includeFileTools = true;
        includeRustScript = true;
      }
    else normalizeFeature default value;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Toolchain                                                 ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeRust = value: let
    default =
      normalizeFeature {
        enable = false;
        kind = "toolchain";
        name = "rust";
        channel = "nightly";
        minimal = false;
        includeDocs = false;
        includeAnalyzer = false;
        includeWeb = false;
        includeLeptos = false;
        includeExtra = false;
        extraTargets = [];
        extraExtensions = [];
      }
      value;
    alias = isAttrs value && isEnabled (value.includeRust or false);
  in
    default // {enable = default.enable || alias;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Workflow                                                  ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeAi = value: let
    default = {
      kind = "workflow";
      name = "ai";
      enable = false;
      includeCodex = false;
      includeClaude = false;
      includeGemini = false;
      includeHermes = false;
      includeOpenClaw = false;
    };

    preset =
      if value == "minimal"
      then {
        enable = true;
        includeCodex = true;
        includeGemini = true;
      }
      else if value == "default"
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
      }
      else if value == "full"
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
        includeHermes = true;
        includeOpenClaw = true;
      }
      else if isEnabled value
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
      }
      else {};
  in
    if isAttrs value
    then
      default
      // preset
      // value
    else default // preset;

  editorGroups = {
    helix = ["helix" "hx"];
    neovim = ["neovim" "nvim"];
    rust-rover = [
      # "idea"
      # "jetbrains"
      "rust-rover"
      "rustrover"
    ];
    sublime = ["sublime-text" "sublime"];
    vscode = [
      "code"
      "cursor"
      "vscode-insiders"
      "vscode"
      "vscodium"
      "windsurf"
    ];
    zed = ["zed" "zeditor"];
  };

  knownEditors = concatLists (attrValues editorGroups);

  #? toPascalCase handles the hyphen: rust-rover → RustRover
  editorShellName = tier: editor:
    concatNonEmpty "" [tier "With" (toPascalCase editor)];

  normalizeEditor = value: let
    default = {
      enable = false;
      kind = "workflow";
      name = "editor";
      editors = [];
    };

    mkGroups = resolved:
      mapAttrs (_: members: hasAny members resolved) editorGroups;

    resolve = input:
      unique (filter (e: elem e knownEditors) (map toLower (toList input)));

    mkResult = resolved:
      default
      // {
        enable = true;
        editors = resolved;
      }
      // mkGroups resolved;
  in
    if isDisabled value
    then default // mkGroups []
    else if isEnabled value
    then (default // {enable = true;}) // mkGroups []
    else if isString value && toLower value == "all"
    then mkResult knownEditors
    else mkResult (resolve value);

  normalizeFormatter = value: let
    web = value.web or {};
    rust = value.rust or {};
    database = value.database or {};

    defaults = {
      enable =
        isEnabled (value.includeFormatter or false)
        || isEnabled (web.enable or false)
        || isEnabled (rust.enable or false)
        || isEnabled (database.enable or false);

      kind = "workflow";
      name = "formatter";

      includeDeno =
        isEnabled (web.enable or false)
        && isEnabled (web.includeDeno or false);

      includePrettier =
        isEnabled (web.enable or false)
        && isEnabled (web.includePrettier or false);

      includeRustfmt =
        isEnabled (rust.enable or false);

      includeLeptosfmt =
        (isEnabled (rust.enable or false)
          && isEnabled (web.enable or false))
        || isEnabled (rust.includeLeptos or false);

      sqlFormatters =
        {}
        // optionalAttrs (isEnabled (database.includeSqlite or false)) {
          sql-sqlite = {
            enable = true;
            dialect = "sqlite";
            includes = ["*.sql"];
          };
        }
        // optionalAttrs (isEnabled (database.includePostgres or false)) {
          sql-postgresql = {
            enable = true;
            dialect = "postgresql";
            includes = ["*.sql"];
          };
        }
        // optionalAttrs (isEnabled (database.includeMysql or false)) {
          sql-mysql = {
            enable = true;
            dialect = "mysql";
            includes = ["*.sql"];
          };
        };
    };
  in
    normalizeFeature defaults (value.formatter or null);

  #╔═══════════════════════════════════════════════════════════╗
  #║ Integration                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeWeb = value: let
    default =
      normalizeFeature {
        enable = false;
        kind = "integration";
        name = "web";
        includeDeno = false;
        includePrettier = false;
        includeTrunk = false;
      }
      value;
    alias = isAttrs value && isEnabled (value.includeWeb or false);
  in
    default // {enable = default.enable || alias;};

  normalizeDatabase = value: let
    default =
      normalizeFeature {
        enable = false;
        kind = "integration";
        name = "database";
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      }
      value;
    alias = isAttrs value && isEnabled (value.includeDatabase or false);
  in
    default // {enable = default.enable || alias;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Orchestrators                                             ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeFeature = default: value:
    if isDisabled value
    then default // {enable = false;}
    else if isAttrs value
    then default // value // {enable = isEnabled (value.enable or true);}
    else if isEnabled value
    then default // {enable = true;}
    else default;

  normalizeVariant = value: {
    __variantName = value.__variantName or null;
    common = normalizeCommon (value.common or true);
    extra = normalizeExtra (value.extra or null);
    ai = normalizeAi (value.ai or null);
    rust = normalizeRust (value.rust or null);
    web = normalizeWeb (value.web or null);
    database = normalizeDatabase (value.database or null);
    editor = normalizeEditor (value.editor or null);
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Constructors                                              ║
  #╚═══════════════════════════════════════════════════════════╝
  mkVariant = {
    config,
    name,
    raw,
  }:
    recursiveUpdate
    config
    (raw // {__variantName = name;});

  mkVariants = config:
    mapAttrs
    (name: raw: mkVariant {inherit config name raw;})
    {
      minimal = {
        common = true;
        ai = "minimal";
      };

      default = {
        common = true;
        extra = true;
        rust = true;
        ai = "default";
      };

      full = {
        rust = true;
        web = true;
        database = true;
        ai = "full";
      };

      minimalRustStable = {
        common = true;
        ai = "minimal";
        rust = {
          enable = true;
          minimal = true;
          channel = "stable";
        };
      };

      minimalRustNightly = {
        common = true;
        ai = "minimal";
        rust = {
          enable = true;
          minimal = true;
          channel = "nightly";
        };
      };

      defaultRustStable = {
        common = true;
        extra = true;
        ai = "default";
        rust = {
          enable = true;
          channel = "stable";
        };
      };

      rustWebStable = {
        common = true;
        extra = true;
        ai = "default";
        rust = {
          enable = true;
          channel = "stable";
        };
        web = true;
      };

      fullStable = {
        common = true;
        extra = true;
        ai = "full";
        rust = {
          enable = true;
          channel = "stable";
        };
        web = true;
        database = true;
      };
    };

  updateVariant = {
    variant,
    raw ? {},
    name ? variant.__variantName or null,
  }:
    normalizeVariant (
      recursiveUpdate
      variant
      (raw // {__variantName = name;})
    );

  updateVariants = {
    variants,
    config,
  }:
    mapAttrs (name: variant:
      updateVariant {
        inherit name variant;
        raw = config.${name} or {};
      })
    variants;

  mkVariantShells = {
    inputs,
    pkgs,
    variants,
    extraPackages ? [],
    extraEnv ? {},
    extraShellHook ? "",
  }: let
    base =
      mapAttrs
      (
        variantName: variant:
          mkShell {
            inherit
              inputs
              pkgs
              variant
              extraPackages
              extraEnv
              extraShellHook
              ;
            raw = variants.raw.${variantName};
          }
      )
      variants.final;

    editor = listToAttrs (
      concatMap
      (
        variantName:
          map
          (editorName: let
            raw =
              recursiveUpdate
              variants.raw.${variantName}
              {editor = editorName;};
            variant = normalizeVariant raw;
          in {
            name = editorShellName variantName editorName;
            value = mkShell {
              inherit
                inputs
                pkgs
                variant
                raw
                extraPackages
                extraEnv
                extraShellHook
                ;
            };
          })
          (attrNames editorGroups)
      )
      (attrNames variants.raw)
    );
  in
    base // editor;

  toVariantJSON = variant: let
    prefix = "__VARIANT";
    val =
      optionalString
      (isNotEmpty variant)
      (toJSON variant);
    kind =
      optionalString
      (variant ? kind)
      (toUpper variant.kind);
    name =
      optionalString
      (variant ? name)
      (toUpper variant.name);
    var = concatNonEmpty "_" [prefix kind name];
  in
    optionalAttrs (isNotEmpty val) {${var} = val;};
in {
  inherit
    editorGroups
    editorShellName
    knownEditors
    mkVariant
    mkVariants
    mkVariantShells
    toVariantJSON
    normalizeAi
    normalizeCommon
    normalizeDatabase
    normalizeEditor
    normalizeExtra
    normalizeFeature
    normalizeFormatter
    normalizeRust
    normalizeVariant
    normalizeWeb
    updateVariant
    updateVariants
    ;
}
