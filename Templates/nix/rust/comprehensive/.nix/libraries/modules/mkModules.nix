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

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Safely get a field from a module, returning `default` if absent or wrong type.
  # `pred` is an optional type guard (e.g. isAttrs, isList) — pass `_: true` to skip.
  safeGet = {
    module,
    keys, # list of candidate attribute names, tried in order
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

  # ---------------------------------------------------------------------------
  # Collectors
  # ---------------------------------------------------------------------------

  # Returns an attrset of named derivations (deduped by pname/name).
  collectPackages = {
    selector,
    modules,
  }: let
    normalizeName = pkg:
      pkg.pname or (pkg.name or (
        throw "collectPackages: derivation missing pname and name"
      ));

    # selector may return an attrset OR a list — normalise to list.
    flatten = v:
      if isAttrs v
      then attrValues v
      else toList v;
  in
    listToAttrs (
      map
      (pkg: {
        name = normalizeName pkg;
        value = pkg;
      })
      (unique (concatMap (m: flatten (selector m)) modules))
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

  # ---------------------------------------------------------------------------
  # Module resolution
  # ---------------------------------------------------------------------------

  collectModules = {
    modules,
    priority ? attrNames modules,
  }: let
    prioritized =
      map (
        k:
          modules.${k} or (throw "collectModules: unknown module '${k}'")
      )
      priority;
    ordered = reverseList prioritized; # highest-priority module is last → wins in foldl'
    all = modules;
  in {inherit all priority prioritized ordered;};

  # ---------------------------------------------------------------------------
  # Package selector
  # ---------------------------------------------------------------------------
  # Modules expose packages in different shapes:
  #   { packages = <drv-attrset> }                        — simple flat attrset
  #   { packages = [ <drv> … ] }                          — list of derivations
  #   { packages = { all = …; common = …; custom = …; } } — mkTreefmt-style wrapper
  #   { pkgs = <drv-attrset or list> }                    — legacy name
  #   (nothing)                                           — return []
  #
  # collectPackages expects a *list* of derivations from this selector —
  # it dedupes and re-keys them itself.
  packageSelector = module: let
    raw = safeGet {
      inherit module;
      keys = ["packages" "pkgs"];
      default = [];
      pred = _: true; # accept any shape; we discriminate below
    };
    # Unwrap mkTreefmt-style { all = …; common = …; custom = …; }
    unwrap = v:
      if isAttrs v && v ? all && isAttrs v.all
      then v.all
      else v;
    normalised = unwrap raw;
  in
    # normalised is now either an attrset of drvs or a list of drvs
    if isAttrs normalised
    then attrValues normalised
    else toList normalised;

  # ---------------------------------------------------------------------------
  # Binary selector
  # ---------------------------------------------------------------------------
  binarySelector = module:
    safeGet {
      inherit module;
      keys = ["binaries" "bin" "commands"];
      default = {};
      pred = isAttrs;
    };

  # The `binaries` field of mkTreefmt is also a wrapper ({ all, common, custom }).
  # Unwrap it the same way.
  flatBinarySelector = module: let
    raw = binarySelector module;
    isWrapped = raw ? all && isAttrs raw.all;
  in
    if isWrapped
    then raw.all
    else raw;

  # ---------------------------------------------------------------------------
  # Variable selector
  # ---------------------------------------------------------------------------
  variableSelector = module:
    safeGet {
      inherit module;
      keys = ["variables" "env" "environment"];
      default = {};
      pred = isAttrs;
    };

  # The cfg we want to serialise is the *final* resolved config, not the debug
  # wrapper.  Modules should expose it as `cfg.final` or just `cfg` (flat).
  cfgSelector = module: let
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

  # ---------------------------------------------------------------------------
  # Message selector
  # ---------------------------------------------------------------------------
  messageSelector = module:
    safeGet {
      inherit module;
      keys = ["messages" "shellHook" "shellHookParts"];
      default = null;
      pred = _: true;
    };

  # ---------------------------------------------------------------------------
  # mkModules
  # ---------------------------------------------------------------------------
  mkModules = {
    inputs,
    pkgs,
    variant ? testVariant {},
  }: let
    collected = collectModules {
      priority = [
        "formatting"
        # "rust"
        # "ai"
        # "web"
        "database"
        "extra"
        "common"
      ];
      modules = {
        # ai        = mkAI      {inherit pkgs variant;};
        common = mkCommon {inherit pkgs variant;};
        database = mkDatabase {inherit pkgs variant;};
        extra = mkExtra {inherit pkgs variant;};
        formatting = mkFormatter {inherit inputs pkgs variant;};
        # rust      = mkRust    {inherit pkgs variant;};
        # web       = mkWeb     {inherit pkgs variant;};
      };
    };

    # ------------------------------------------------------------------
    # Derived collections
    # ------------------------------------------------------------------

    # Named attrset of derivations (deduped).
    packages = collectPackages {
      selector = packageSelector;
      modules = collected.prioritized;
    };

    # Flat list of derivations — useful for devShell `packages = [ ... ]`.
    eval = attrValues packages;

    # Named attrset of binary paths.
    binaries = collectAttrs {
      selector = flatBinarySelector;
      modules = collected.ordered;
    };

    variables =
      {
        PROJECT_PATH = toString project.path;
        PROJECT_NAME = project.name;
      }
      // collectAttrs {
        selector = variableSelector;
        modules = collected.ordered;
      }
      // foldl'
      (merged: m: merged // (toVariantJSON (cfgSelector m)))
      {}
      collected.ordered;

    messages = collectMessages {
      selector = messageSelector;
      modules = collected.prioritized;
    };
  in {
    inherit variant;
    configuration = variant;
    modules = collected.all;

    inherit packages eval binaries variables messages;

    inherit (collected.all.formatting) formatter;
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
