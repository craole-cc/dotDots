{
  lib',
  env,
  path,
  basePath,
  excludedDirs,
  excludedFiles,
  excludedPatterns,
  runTests,
}: let
  inherit (builtins) readDir pathExists currentTime;
  inherit
    (lib'.attrsets)
    attrNames
    foldlAttrs
    isAttrs
    mapAttrs
    filterAttrs
    ;
  inherit
    (lib'.lists)
    elem
    filter
    foldl'
    findFirst
    ;
  inherit
    (lib'.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    removeSuffix
    removePrefix
    typeOf
    ;
  inherit (lib'.trivial) isFunction;

  # scalp = lib'.attrsets.removeAttrs;

  empty = {
    modules = {};
    rootAliases = {};
  };

  # ── Exclusion predicates ────────────────────────────────────────────────
  isExcludedDir = n: elem n excludedDirs || hasPrefix "." n;
  isExcludedFile = n:
    elem n excludedFiles
    || foldl' (acc: pat: acc || hasSuffix pat n) false excludedPatterns;

  # ── Documentation discovery ─────────────────────────────────────────────
  findDocs = dir: moduleName: let
    getRelPath = base: target: removePrefix (toString base + "/") (toString target);
    candidates = [
      (dir + "/${moduleName}.md")
      (dir + "/README.md")
      (dir + "/readme.md")
      (dir + "/docs/${moduleName}.md")
      (dir + "/docs/README.md")
      (path + "/Documentation/${getRelPath path dir}/${moduleName}.md")
      (path + "/Documentation/${getRelPath path dir}/README.md")
    ];
    found = findFirst (p: p != null && pathExists (toString p)) null candidates;
  in
    if found != null
    then {
      type = "markdown";
      source = found;
      available = true;
      locations = filter (p: pathExists (toString p)) candidates;
    }
    else {
      type = "none";
      source = null;
      available = false;
      locations = [];
    };

  # ── .nix file processor ─────────────────────────────────────────────────
  processNixFile = dir: pathPrefix: entryName: let
    moduleName = removeSuffix ".nix" entryName;
    filePath = dir + "/${entryName}";
    rawModule = import filePath;

    importedModule =
      if isFunction rawModule
      then let
        moduleEnv =
          env
          // rec {
            __moduleFile = filePath;
            __moduleName = moduleName;
            __modulePath = [env.library] ++ pathPrefix ++ [moduleName];
            __moduleRef = concatStringsSep "." __modulePath;
          };
        result = rawModule moduleEnv;
      in
        if result == null || !(isAttrs result)
        then throw "Module ${entryName} must return an attribute set, got ${typeOf result}"
        else result
      else if isAttrs rawModule
      then rawModule
      else throw "Module ${entryName} must be either a function or attribute set";

    rootAliases = importedModule._rootAliases or {};

    attrsToRemove =
      ["_rootAliases"]
      ++ filter
      (n: hasPrefix "_" n && n != "_rootAliases" && n != "_tests" && n != "__meta" && n != "__doc")
      (attrNames importedModule)
      ++ (
        if !runTests
        then ["_tests"]
        else []
      );

    cleanModule = removeAttrs importedModule attrsToRemove;

    mdDocs = findDocs dir moduleName;
    docsInfo =
      if mdDocs.available
      then mdDocs
      else if cleanModule ? __doc
      then {
        type = "string";
        source = cleanModule.__doc;
        available = true;
        locations = [];
      }
      else {
        type = "none";
        source = null;
        available = false;
        locations = [];
      };

    moduleWithMeta =
      cleanModule
      // {
        __meta = {
          module = rec {
            name = concatStringsSep "." namespace;
            path = filePath;
            directory = removePrefix ((toString basePath) + "/") (toString dir);
            filename = entryName;
            namespace = [env.library] ++ pathPrefix ++ [moduleName];
          };
          docs = docsInfo;
          exports = attrNames cleanModule;
          functions = attrNames (filterAttrs (_: v: isFunction v) cleanModule);
          values = attrNames (filterAttrs (_: v: !isFunction v) cleanModule);
          timestamp = currentTime;
        };
      };
  in {
    modules = {${moduleName} = moduleWithMeta;};
    rootAliases = rootAliases;
  };

  # ── Recursive directory scanner ─────────────────────────────────────────
  scanDir = dir: pathPrefix: let
    processEntry = entryName: entryType:
      if entryType == "directory" && isExcludedDir entryName
      then empty
      else if entryType == "directory"
      then let
        sub = dir + "/${entryName}";
        res = scanDir sub (pathPrefix ++ [entryName]);
      in {
        modules =
          if res.modules != {}
          then {${entryName} = res.modules;}
          else {};
        rootAliases = res.rootAliases;
      }
      else if entryType == "regular" && hasSuffix ".nix" entryName && !isExcludedFile entryName
      then processNixFile dir pathPrefix entryName
      else empty;

    processed = mapAttrs processEntry (readDir dir);
  in
    foldlAttrs
    (acc: _: v: {
      modules = acc.modules // v.modules;
      rootAliases = acc.rootAliases // v.rootAliases;
    })
    empty
    processed;
in
  scanDir
