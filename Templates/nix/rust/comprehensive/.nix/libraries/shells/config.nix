{ lib }:
let
  inherit (lib.attrsets)
    attrNames
    attrValues
    listToAttrs
    mapAttrs
    recursiveUpdate
    ;
  inherit (lib.lists)
    concatMap
    foldl'
    reverseList
    unique
    ;
  inherit (lib.meta) project;
  inherit (lib.packages)
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
  inherit (lib.shells)
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

  mkVariant =
    {
      config,
      name,
      raw,
    }:
    recursiveUpdate config (raw // { __variantName = name; });

  mkVariants =
    config:
    mapAttrs (name: raw: mkVariant { inherit config name raw; }) {
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
  collectModules =
    {
      modules,
      priority ? attrNames modules,
    }:
    let
      prioritized = map (name: modules.${name} or (throw "collectModules: unknown module '${name}'")) priority;

      ordered = reverseList prioritized;
    in
    {
      all = modules;
      inherit priority prioritized ordered;
    };

  collectPackages =
    f: xs:
    let
      normalize = pkg: pkg.pname or (pkg.name or (throw "Expected derivation-like value with pname or name"));
    in
    listToAttrs (
      map (pkg: {
        name = normalize pkg;
        value = pkg;
      }) (unique (concatMap f xs))
    );

  collectAttrs = f: xs: foldl' (acc: x: acc // (f x)) { } xs;

  mkModules =
    { pkgs, variant }:
    let
      collected = collectModules {
        priority = [
          "rust"
          "ai"
          "web"
          "database"
          "extra"
          "common"
        ];
        modules = {
          ai = mkAI { inherit pkgs variant; };
          common = mkCommon { inherit pkgs variant; };
          extra = mkExtra { inherit pkgs variant; };
          database = mkDatabase { inherit pkgs variant; };
          rust = mkRust { inherit pkgs variant; };
          web = mkWeb { inherit pkgs variant; };
        };
      };
    in
    {
      modules = collected.all;
      packages = collectPackages (m: m.packages.all or [ ]) collected.prioritized;
      binaries = collectAttrs (m: m.binaries.all or { }) collected.ordered;
    };

  mkShellSpec =
    {
      pkgs,
      variant,
      raw ? { },
      formatting,
      extraPackages ? [ ],
      extraEnv ? { },
    }:
    let
      inherit (mkModules { inherit pkgs variant; }) modules;
    in
    {
      packages =
        with modules;
        extraPackages
        ++ (rust.all or [ ])
        ++ (ai.all or [ ])
        ++ (web.all or [ ])
        ++ (database.all or [ ])
        ++ (extra.all or [ ])
        ++ (common.all or [ ])
        ++ attrValues (formatting.packages.${getSystem pkgs} or { });

      env = {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
        DEVSHELL_NAME = variant.__variantName or modules.variantName;
        DEVSHELL = toJSON variant;
        DEVSHELL_AI = toJSON variant.ai;
        DEVSHELL_RUST = toJSON variant.rust;
        DEVSHELL_WEB = toJSON variant.web;
        DEVSHELL_EXTRA = toJSON variant.extra;
        DEVSHELL_DATABASE = toJSON variant.database;
        DEVSHELL_EDITOR = toJSON variant.editor;
        DEVSHELL_RAW = toJSON (if raw != null then raw else variant);
      }
      // (modules.ai.env or { })
      // (modules.common.env or { })
      // (modules.extra.env or { })
      // (modules.database.env or { })
      // (modules.web.env or { })
      // (modules.rust.env or { })
      # // {
      #   __DEVSHELL_NAME = variant.__variantName or "unknown";
      #   __DEVSHELL_AI = toJSON variant.ai;
      #   __DEVSHELL_RUST = toJSON variant.rust;
      #   __DEVSHELL_WEB = toJSON variant.web;
      #   __DEVSHELL_EXTRA = toJSON variant.extra;
      #   __DEVSHELL_DATABASE = toJSON variant.database;
      #   __DEVSHELL_EDITOR = toJSON variant.editor;
      #   __DEVSHELL_RAW = toJSON (
      #     if raw != null
      #     then raw
      #     else {}
      #   );
      # }
      // extraEnv;

      shellHook = "";
    };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Environment                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  mkEnvironment =
    {
      inputs,
      self,
      pkgs ? mkPkgs { inherit inputs; },
      config ? { },
      extraPackages ? [ ],
      extraEnv ? { },
    }:
    let
      variants = rec {
        prev = mkVariants config;
        final = mapAttrs (_: normalizeVariant) prev;
      };

      formatting = mkFormatting { inherit inputs self; } variants.final.default;

      templates = deployTemplates {
        inherit pkgs;
        variant = variants.final.default;
      };

      shells =
        let
          ## Variant Normalization
          #? Base shells use normalized `variants.final`. Editor shells inject into raw `variants.prev`
          #? then normalize. See [AI Shell Variants Documentation](ai-shell-docs.md) for details.
          base = mapAttrs (
            name: variant:
            mkShellSpec {
              inherit
                pkgs
                variant
                formatting
                extraPackages
                extraEnv
                ;
              raw = variants.prev.${name};
            }
          ) variants.final;

          editor = listToAttrs (
            concatMap (
              variantName:
              map (editorName: {
                name = editorShellName variantName editorName;
                value =
                  let
                    raw = recursiveUpdate variants.prev.${variantName} { editor = editorName; };
                    variant = normalizeVariant raw;
                    spec = mkShellSpec {
                      inherit
                        pkgs
                        formatting
                        extraPackages
                        extraEnv
                        variant
                        raw
                        ;
                    };
                  in
                  spec;
              }) (attrNames editorGroups)
            ) (attrNames variants.prev)
          );
        in
        base // editor;
    in
    {
      inherit templates;
      inherit (formatting) formatter checks;

      devShells = mkShells { inherit inputs shells; };
      inherit
        (mkModules {
          inherit pkgs;
          variant = variants.final.default;
        })
        modules
        packages
        binaries
        ;
    };
in
{
  inherit
    mkEnvironment
    mkModules
    mkVariant
    mkVariants
    ;
}
