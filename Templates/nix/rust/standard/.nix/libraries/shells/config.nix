{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    listToAttrs
    mapAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) concatMap;
  inherit (lib.meta) project;
  inherit
    (lib.packages)
    getSystem
    mkAI
    mkCommon
    mkDatabase
    mkExtra
    mkFormatting
    mkPkgs
    mkRust
    mkWeb
    ;
  inherit
    (lib.shells)
    editorGroups
    editorShellName
    mkShells
    normalizeVariant
    ;
  inherit (lib.strings) toJSON;
  inherit (lib.templates) deployTemplates;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Variants                                                  ║
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

  #╔═══════════════════════════════════════════════════════════╗
  #║ Modules                                                   ║
  #╚═══════════════════════════════════════════════════════════╝

  mkModules = {
    pkgs,
    variant,
  }: {
    ai = mkAI {inherit pkgs variant;};
    common = mkCommon {inherit pkgs variant;};
    extra = mkExtra {inherit pkgs variant;};
    database = mkDatabase {inherit pkgs variant;};
    rust = mkRust {inherit pkgs variant;};
    web = mkWeb {inherit pkgs variant;};
  };

  mkExportedPackages = modules:
    with modules;
      common.all
      ++ extra.all
      ++ database.all
      ++ web.all
      ++ ai.all
      ++ rust.all;

  mkShellSpec = {
    pkgs,
    variant,
    raw ? {},
    formatting,
    extraPackages ? [],
    extraEnv ? {},
  }: let
    modules = mkModules {inherit pkgs variant;};
  in {
    packages = with modules;
      extraPackages
      ++ (rust.all or [])
      ++ (web.all or [])
      ++ (database.all or [])
      ++ (extra.all or [])
      ++ (common.all or [])
      ++ attrValues (formatting.packages.${getSystem pkgs} or {});

    env =
      {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
        DEVSHELL_NAME = variant.__variantName or modules.variantName;
        DEVSHELL = toJSON variant;
        DEVSHELL_RAW = toJSON raw;
        DEVSHELL_AI = toJSON variant.ai;
        DEVSHELL_RUST = toJSON variant.rust;
      }
      // (modules.ai.env or {})
      // (modules.common.env or {})
      // (modules.extra.env or {})
      // (modules.database.env or {})
      // (modules.web.env or {})
      // (modules.rust.env or {})
      // extraEnv;

    shellHook = "";
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Environment                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  mkEnvironment = {
    inputs,
    self,
    pkgs ? mkPkgs {inherit inputs;},
    config ? {},
    extraPackages ? [],
    extraEnv ? {},
  }: let
    variants = rec {
      prev = mkVariants config;
      final = mapAttrs (_: normalizeVariant) prev;
    };

    formatting =
      mkFormatting
      {inherit inputs self;}
      variants.final.default;

    templates = deployTemplates {
      inherit pkgs;
      variant = variants.final.default;
    };

    shells = let
      ## Variant Normalization
      #? Base shells use normalized `variants.final`. Editor shells inject into raw `variants.prev`
      #? then normalize. See [AI Shell Variants Documentation](ai-shell-docs.md) for details.
      base =
        mapAttrs
        (
          name: variant:
            mkShellSpec {
              inherit pkgs variant formatting extraPackages extraEnv;
              raw = variants.prev.${name};
            }
        )
        variants.final;

      editor = listToAttrs (concatMap (
        variantName:
          map (editorName: {
            name = editorShellName variantName editorName;
            value = let
              raw = recursiveUpdate variants.prev.${variantName} {editor = editorName;};
              variant = normalizeVariant raw;
              spec = mkShellSpec {
                inherit pkgs formatting extraPackages extraEnv variant raw; # ← thread raw in
              };
            in
              spec;
          }) (attrNames editorGroups)
      ) (attrNames variants.prev));
    in
      base // editor;

    defaultModules = mkModules {
      inherit pkgs;
      variant = variants.final.default;
    };
  in {
    inherit templates;
    inherit (formatting) formatter checks;

    devShells = mkShells {inherit inputs shells;};

    packages = listToAttrs (
      map
      (p: {
        name = p.pname or p.name;
        value = p;
      })
      (mkExportedPackages defaultModules)
    );
  };
in {inherit mkEnvironment mkModules mkVariant mkVariants;}
