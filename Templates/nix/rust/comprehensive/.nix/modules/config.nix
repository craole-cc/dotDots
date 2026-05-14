{lib}: let
  inherit (lib.attrsets) attrValues mapAttrs;
  inherit
    (lib.modules)
    collectModules
    collectPackages
    collectMessages
    collectAttrs
    normalizeModule
    ;
  inherit (lib.lists) foldl';
  inherit (lib.meta) project;
  inherit
    (lib.shells)
    mkVariantShells
    mkShells
    mkVariants
    normalizeVariant
    ;
  inherit
    (lib.packages)
    getSystem
    mkAI
    mkChecker
    mkCommon
    mkDatabase
    mkExtra
    mkFormatter
    mkPkgs
    mkPkgsPerSystem
    mkRust
    mkWeb
    perSystem
    ;
  inherit (lib.shells) testVariant toVariantJSON;
  # inherit (lib.templates) deployTemplates;

  mkModules = {
    inputs,
    pkgs,
    variant ? testVariant {},
  }: let
    collected = collectModules {
      priority = [
        "formatting"
        "rust"
        "ai"
        "web"
        "database"
        "extra"
        "common"
      ];
      modules = {
        ai = mkAI {inherit pkgs variant;};
        common = mkCommon {inherit pkgs variant;};
        database = mkDatabase {inherit pkgs variant;};
        extra = mkExtra {inherit pkgs variant;};
        formatting = mkFormatter {inherit inputs pkgs variant;};
        rust = mkRust {inherit pkgs variant;};
        web = mkWeb {inherit pkgs variant;};
      };
    };
    modules = with collected; {
      raw = all;
      normalized = mapAttrs (_: normalizeModule) all;
    };
    #╔═══════════════════════════════════════════════════════════╗
    #║ Derived Collections                                       ║
    #╚═══════════════════════════════════════════════════════════╝
    packages = collectPackages {
      selector = m: m.packages;
      modules = collected.prioritized;
    };
    eval = attrValues packages;

    binaries = collectAttrs {
      selector = m: m.binaries;
      modules = collected.ordered;
    };

    variables =
      {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
      }
      // collectAttrs {
        selector = m: m.variables;
        modules = collected.ordered;
      }
      // foldl' (merged: m: merged // (toVariantJSON m.configuration)) {} collected.ordered;

    messages = collectMessages {
      selector = m: m.messages;
      modules = collected.prioritized;
    };
  in {
    inherit
      lib
      pkgs
      project
      modules
      packages
      eval
      binaries
      variables
      messages
      ;
    configuration = variant;
  };

  mkConfig = {
    inputs,
    self,
    pkgs ? mkPkgs {inherit inputs;},
    configuration ? null,
    config ? {},
    extraPackages ? [],
    extraEnv ? {},
    extraShellHook ? "",
    variantName ? "default",
  }: let
    # system = pkgs.stdenv.hostPlatform.system;
    system = getSystem pkgs;
    variants = let
      raw = mkVariants config;
      final = mapAttrs (_: normalizeVariant) raw;
    in {
      inherit raw final;
    };

    variant =
      if configuration != null
      then configuration
      else variants.final.${variantName} or (throw "mkConfig: unknown variantName '${variantName}'");

    exports = mkModules {inherit inputs pkgs variant;};
    # templates = deployTemplates {inherit pkgs variant;};
  in {
    inherit exports;
    inherit (exports) lib;

    checks = mkChecker {inherit inputs self variant;};

    devShells = mkShells {
      inherit inputs;
      shells = mkVariantShells {
        inherit
          inputs
          pkgs
          variants
          extraPackages
          extraEnv
          extraShellHook
          ;
      };
    };

                  formatter =
                     exports.modules.raw.formatting.formatter;

    packages = perSystem {
      inherit inputs;
      fn = pkgs: (mkModules {inherit inputs pkgs variant;}).packages;
    };

    legacyPackages = mkPkgsPerSystem {inherit inputs;};
  };
in {
  inherit mkModules mkConfig;
}
