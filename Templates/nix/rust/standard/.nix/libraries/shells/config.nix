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

  mkVariants = config: let
    mkVariant = tier: recursiveUpdate tier config;
  in {
    minimal = mkVariant {
      common = true;
      ai = "minimal";
    };

    default = mkVariant {
      common = true;
      extra = true;
      rust = true;
      ai = "default";
    };

    full = mkVariant {
      rust = true;
      web = true;
      database = true;
      ai = "full";
    };

    rust = mkVariant {
      rust = true;
    };

    rust-web = mkVariant {
      rust = true;
      web = true;
    };

    rust-database = mkVariant {
      rust = true;
      database = true;
    };

    rust-web-database = mkVariant {
      rust = true;
      web = true;
      database = true;
    };

    minimalRustStable = mkVariant {
      common = true;
      ai = "minimal";
      rust = {
        enable = true;
        minimal = true;
        channel = "stable";
      };
    };

    minimalRustNightly = mkVariant {
      common = true;
      ai = "minimal";
      rust = {
        enable = true;
        minimal = true;
        channel = "nightly";
      };
    };

    defaultRustStable = mkVariant {
      common = true;
      extra = true;
      ai = "default";
      rust = {
        enable = true;
        channel = "stable";
      };
    };

    rustWebStable = mkVariant {
      common = true;
      extra = true;
      ai = "default";
      rust = {
        enable = true;
        channel = "stable";
      };
      web = true;
    };

    fullStable = mkVariant {
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
    tierRaws = mkVariants config;

    tierVariants = mapAttrs (_: normalizeVariant) tierRaws;

    formatting = mkFormatting {inherit inputs self;} tierVariants.default;

    templates = deployTemplates {
      inherit pkgs;
      variant = tierVariants.default;
    };

    baseShells =
      mapAttrs
      (_: variant:
        mkShellSpec {
          inherit pkgs variant formatting extraPackages extraEnv;
        })
      tierVariants;

    editorShells = listToAttrs (
      concatMap
      (
        tierName:
          map
          (editorName: {
            name = editorShellName tierName editorName;
            value = mkShellSpec {
              inherit pkgs formatting extraPackages extraEnv;
              variant = normalizeVariant (
                recursiveUpdate
                tierRaws.${tierName}
                {editor = editorName;}
              );
            };
          })
          (attrNames editorGroups)
      )
      (attrNames tierRaws)
    );

    shells = baseShells // editorShells;

    defaultModules = mkModules {
      inherit pkgs;
      variant = tierVariants.default;
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
