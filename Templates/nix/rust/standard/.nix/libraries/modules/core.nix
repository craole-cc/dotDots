{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    isAttrs
    listToAttrs
    ;
  inherit
    (lib.lists)
    concatMap
    foldl'
    optionals
    reverseList
    toList
    unique
    ;
  inherit (lib.meta) project;
  inherit
    (lib.packages)
    mkAI
    mkCommon
    mkDatabase
    mkExtra
    mkFormatter
    mkPkgsPerSystem
    mkRust
    mkWeb
    ;
  inherit (lib.shells) testVariant toVariantJSON;

  # collectPackages = {
  #   selector,
  #   modules,
  # }: let
  #   normalizeName = package:
  #     package.pname or (package.name or (
  #       throw "Expected derivation-like value with pname or name"
  #     ));
  # in
  #   listToAttrs (
  #     map
  #     (package: {
  #       name = normalizeName package;
  #       value = package;
  #     })
  #     (unique (concatMap selector modules))
  #   );

  collectPackages = {
    selector,
    modules,
  }: let
    normalizePackageName = package:
      package.pname or (package.name or (
        throw "Expected derivation-like value with pname or name"
      ));

    flattenToList = value:
      if isAttrs value
      then attrValues value
      else toList value;
  in
    listToAttrs (
      map
      (package: {
        name = normalizePackageName package;
        value = package;
      })
      (unique (concatMap (x: flattenToList (selector x)) modules))
    );

  collectAttrs = {
    selector,
    modules,
  }:
    foldl'
    (merged: module: merged // (selector module))
    {}
    modules;

  collectMessages = {
    selector,
    modules,
  }:
    concatMap
    (module:
      optionals
      ((selector module) != null)
      (toList (selector module)))
    modules;

  collectModules = {
    modules,
    priority ? attrNames modules,
  }: let
    prioritized =
      map
      (
        module:
          modules.${
            module
          } or (
            throw "collectModules: unknown module '${module}'"
          )
      )
      priority;

    ordered = reverseList prioritized;
    all = modules;
  in {inherit all priority prioritized ordered;};

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
  in {
    configuration = variant;
    modules = collected.all;

    packages = collectPackages {
      selector = module:
        module.packages.all or (module.pkgs or (module.packages or []));
      modules = collected.prioritized;
    };

    binaries = collectAttrs {
      selector = module:
        module.binaries.all or (module.bin or (module.commands or (module.binaries or {})));
      modules = collected.ordered;
    };

    variables =
      {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
      }
      // collectAttrs {
        selector = module:
          module.variables or (module.env or (module.environment or {}));
        modules = collected.ordered;
      }
      // foldl'
      (
        merged: module:
          merged // (toVariantJSON (module.cfg or (module.variant or {})))
      )
      {}
      collected.ordered;

    messages = collectMessages {
      selector = module:
        module.messages or (module.shellHook or (module.shellHookParts or []));
      modules = collected.prioritized;
    };

    inherit lib pkgs project;
    legacyPackages = mkPkgsPerSystem {inherit inputs;};
  };
in {
  inherit
    collectModules
    collectPackages
    collectAttrs
    collectMessages
    mkModules
    ;
}
