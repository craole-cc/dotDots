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
    filterAttrs
    foldlAttrs
    isAttrs
    mapAttrs
    ;
  inherit
    (lib'.lists)
    elem
    filter
    findFirst
    foldl'
    length
    ;
  inherit
    (lib'.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    removePrefix
    removeSuffix
    splitString
    typeOf
    ;
  inherit (lib'.trivial) isFunction;

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

    normalizedModule =
      importedModule
      // (
        if importedModule ? __doc && !(importedModule ? __docs)
        then {__docs = importedModule.__doc;}
        else {}
      )
      // (
        if importedModule ? _tests && !(importedModule ? __tests)
        then {__tests = importedModule._tests;}
        else {}
      );

    rootAliases =
      if normalizedModule ? __rootAliases
      then normalizedModule.__rootAliases
      else normalizedModule._rootAliases or {};

    attrsToRemove =
      ["_rootAliases" "__rootAliases" "__doc" "_tests"]
      ++ filter
      (
        n:
          hasPrefix "_" n
          && n != "_rootAliases"
          && n != "__rootAliases"
          && n != "__meta"
          && n != "__docs"
          && n != "__tests"
      )
      (attrNames normalizedModule)
      ++ (
        if !runTests
        then ["_tests" "__tests"]
        else []
      );

    cleanModule = removeAttrs normalizedModule attrsToRemove;

    meta = let
      module = rec {
        name = concatStringsSep "." namespace;
        path = filePath;
        directory = removePrefix ((toString basePath) + "/") (toString dir);
        filename = entryName;
        namespace = [env.library] ++ pathPrefix ++ [moduleName];
      };

      exports = filterAttrs (n: _: !(hasPrefix "__" n)) cleanModule;

      docs = let
        mdDocs = findDocs dir moduleName;
        available = cleanModule ? __docs;
      in
        if mdDocs.available
        then mdDocs
        else if available
        then rec {
          inherit available;
          type = "string";
          source = concatStringsSep "." [module.name "__docs"];
          location = splitString "." source;
        }
        else {
          inherit available;
          type = "none";
        };

      tests = let
        available = cleanModule ? __tests;
      in
        if available
        then let
          results =
            foldlAttrs
            (acc: _: group:
              acc
              ++ (
                if isAttrs group
                then map (n: group.${n}) (attrNames group)
                else []
              ))
            []
            cleanModule.__tests;
          total = length results;
          passed = length (filter (t: t.passed or false) results);
          failed = total - passed;
        in {inherit available total passed failed;}
        else {inherit available;};
    in
      cleanModule
      // {
        __meta = {
          inherit module docs tests;
          exports = attrNames exports;
          functions =
            attrNames
            (filterAttrs (_: v: isFunction v) exports);
          values =
            attrNames
            (filterAttrs (_: v: !isFunction v) exports);
          timestamp = currentTime;
        };
      };
  in {
    modules = {${moduleName} = meta;};
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
