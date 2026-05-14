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
    # mkAI
    mkCommon
    mkDatabase
    mkExtra
    mkFormatter
    mkPkgsPerSystem
    mkRust
    mkWeb
    ;
  inherit (lib.shells) testVariant toVariantJSON;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Getters                                                   ║
  #╚═══════════════════════════════════════════════════════════╝
  safeGet = {
    module,
    keys,
    default,
    pred ? (_: true),
  }: let
    tryKey = acc: key:
      if acc != null
      then acc
      else if module ? ${key} && pred module.${key}
      then module.${key}
      else null;
    found = foldl' tryKey null keys;
  in
    if found != null
    then found
    else default;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Selectors                                                 ║
  #╚═══════════════════════════════════════════════════════════╝
  selectPackages = module: let
    raw = safeGet {
      inherit module;
      keys = ["packages" "pkgs"];
      default = [];
      pred = _: true;
    };
    unwrap = v:
      if isAttrs v && v ? all && isAttrs v.all
      then v.all
      else v;
    normalised = unwrap raw;
  in
    if isAttrs normalised
    then attrValues normalised
    else toList normalised;

  selectBinaries = module: let
    raw = safeGet {
      inherit module;
      keys = ["binaries" "bin" "commands"];
      default = {};
      pred = isAttrs;
    };
    isWrapped = raw ? all && isAttrs raw.all;
  in
    if isWrapped then raw.all else raw;

  selectVariables = module:
    safeGet {
      inherit module;
      keys = ["variables" "env" "environment"];
      default = {};
      pred = isAttrs;
    };

  selectConfiguration = module: let
    raw = safeGet {
      inherit module;
      keys = ["configuration" "cfg" "variant"];
      default = {};
      pred = isAttrs;
    };
  in
    if raw ? final && isAttrs raw.final
    then raw.final
    else raw;

  selectMessaging = module:
    safeGet {
      inherit module;
      keys = ["messages" "shellHook" "shellHookParts"];
      default = null;
      pred = _: true;
    };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Normalizer                                                ║
  #╚═══════════════════════════════════════════════════════════╝
  #? Ensures every module exposes the same standard fields,
  #? regardless of what the underlying mk* function returned.
  normalizeModule = module: {
    packages      = selectPackages      module;  # list of derivations
    binaries      = selectBinaries      module;  # attrset of name → store path
    variables     = selectVariables     module;  # attrset of env vars
    configuration = selectConfiguration module;  # flat resolved cfg attrset
    messages      = selectMessaging     module;  # list of strings | null
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Collectors                                                ║
  #╚═══════════════════════════════════════════════════════════╝
  #? Returns an attrset of named derivations (deduped by pname/name).
  #? Expects selector to return a list (guaranteed after normalizeModule).
  collectPackages = {
    selector,
    modules,
  }: let
    normalizeName = pkg:
      pkg.pname or (pkg.name or (
        throw "collectPackages: derivation missing pname and name"
      ));
  in
    listToAttrs (
      map
      (pkg: {name = normalizeName pkg; value = pkg;})
      (unique (concatMap (m: selector m) modules))
    );

  # Returns an attrset, last writer wins (ordered = highest-priority module last).
  collectAttrs = {
    selector,
    modules,
  }:
    foldl'
    (merged: m: merged // (selector m))
    {}
    modules;

  collectMessages = {
    selector,
    modules,
  }:
    concatMap
    (m: optionals ((selector m) != null) (toList (selector m)))
    modules;

  collectModules = {
    modules,
    priority ? attrNames modules,
  }: let
    #? Resolve in priority order, normalizing each module on the way in.
    #? After this point every element has the same standard shape.
    prioritized = map (k:
      normalizeModule (
        modules.${k} or (throw "collectModules: unknown module '${k}'")
      )
    ) priority;
    #? highest-priority module is last → wins in foldl'
    ordered = reverseList prioritized;
    #? Preserve raw mk* outputs so callers can still access module-specific
    #? fields (e.g. modules.formatting.formatter, modules.formatting.eval).
    all = modules;
  in {inherit all priority prioritized ordered;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Constructors                                              ║
  #╚═══════════════════════════════════════════════════════════╝
  mkModules = {
    inputs,
    pkgs,
    variant ? testVariant {},
  }: let
    collected = collectModules {
      priority = [
        "formatting"
        "rust"
        # "ai"
        "web"
        "database"
        "extra"
        "common"
      ];
      modules = {
        # ai        = mkAI      {inherit pkgs variant;};
        common    = mkCommon   {inherit pkgs variant;};
        database  = mkDatabase {inherit pkgs variant;};
        extra     = mkExtra    {inherit pkgs variant;};
        formatting= mkFormatter{inherit inputs pkgs variant;};
        rust      = mkRust     {inherit pkgs variant;};
        web       = mkWeb      {inherit pkgs variant;};
      };
    };
    #? Raw mk* outputs — use for module-specific fields not in the standard shape.
    modules = collected.all;

    #╔═══════════════════════════════════════════════════════════╗
    #║ Derived Collections                                       ║
    #╚═══════════════════════════════════════════════════════════╝
    #? All collectors use collected.prioritized / .ordered —
    #? normalized modules with guaranteed field shapes.

    packages = collectPackages {
      selector = m: m.packages;  # list after normalizeModule
      modules  = collected.prioritized;
    };
    eval = attrValues packages;  # flat list, ready for devShell.packages

    binaries = collectAttrs {
      selector = m: m.binaries;
      modules  = collected.ordered;
    };

    variables =
      {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
      }
      // collectAttrs {
        selector = m: m.variables;
        modules  = collected.ordered;
      }
      // foldl'
      (merged: m: merged // (toVariantJSON m.configuration))
      {}
      collected.ordered;

    messages = collectMessages {
      selector = m: m.messages;
      modules  = collected.prioritized;
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
    inherit (modules.formatting) formatter;
    configuration = variant;

    legacyPackages = mkPkgsPerSystem {inherit inputs;};
  };
in {
  inherit
    collectAttrs
    collectMessages
    collectModules
    collectPackages
    mkModules
    normalizeModule
    selectBinaries
    selectConfiguration
    selectMessaging
    selectPackages
    selectVariables
    ;
}
