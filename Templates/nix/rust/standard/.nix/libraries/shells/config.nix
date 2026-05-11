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
  inherit
    (lib.packages)
    getSystem
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
  inherit (lib.templates) deployTemplates;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Tiers                                                     ║
  #╚═══════════════════════════════════════════════════════════╝

  # mkVariant = config: tier: recursiveUpdate tier config;

  mkVariants = config:
    mapAttrs
    (
      name: tier:
        recursiveUpdate config (tier // {__variantName = name;})
    )
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

      rust = {
        rust = true;
      };

      rust-web = {
        rust = true;
        web = true;
      };

      rust-database = {
        rust = true;
        database = true;
      };

      rust-web-database = {
        rust = true;
        web = true;
        database = true;
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
    common = mkCommon {inherit pkgs variant;};
    extra = mkExtra {inherit pkgs variant;};
    database = mkDatabase {inherit pkgs variant;};
    rust = mkRust {inherit pkgs variant;};
    web = mkWeb {inherit pkgs variant;};
  };

  mkExportedPackages = modules:
    modules.common.all
    ++ modules.extra.all
    ++ modules.database.all
    ++ modules.web.all
    ++ modules.rust.all;

  mkShellSpec = {
    pkgs,
    variant,
    formatting,
    extraPackages ? [],
    extraEnv ? {},
  }: let
    modules = mkModules {inherit pkgs variant;};
  in {
    packages =
      extraPackages
      ++ (modules.rust.all or [])
      ++ (modules.web.all or [])
      ++ (modules.database.all or [])
      ++ (modules.extra.all or [])
      ++ (modules.common.all or [])
      ++ attrValues (formatting.packages.${getSystem pkgs} or {});

    env =
      {}
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
      base =
        mapAttrs
        (name: variant: let
          spec = mkShellSpec {
            inherit pkgs variant formatting extraPackages extraEnv;
          };
        in
          spec
          // {
            env =
              spec.env
              // {
                DEVSHELL_VARIANT_NAME = variant.__variantName or name;
                DEVSHELL_VARIANT = builtins.toJSON variant;
                DEVSHELL_VARIANT_RAW = builtins.toJSON variants.prev.${name};
              };
          })
        variants.final;

      editor = listToAttrs (
        concatMap
        (
          variantName:
            map
            (editorName: {
              name = editorShellName variantName editorName;
              value = let
                raw = recursiveUpdate variants.prev.${variantName} {editor = editorName;};
                variant = normalizeVariant raw;
                spec = mkShellSpec {
                  inherit pkgs formatting extraPackages extraEnv variant;
                };
              in
                spec
                // {
                  env =
                    spec.env
                    // {
                      DEVSHELL_VARIANT_NAME = variant.__variantName or variantName;
                      DEVSHELL_VARIANT = builtins.toJSON variant;
                      DEVSHELL_VARIANT_RAW = builtins.toJSON raw;
                    };
                };
            })
            (attrNames editorGroups)
        )
        (attrNames variants.prev)
      );
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
in {inherit mkEnvironment mkModules mkVariants;}
