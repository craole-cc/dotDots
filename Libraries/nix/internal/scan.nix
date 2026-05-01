{
  lib,
  env,
  exclusions,
  paths,
  runTests,
}: let
  inherit (builtins) readDir pathExists currentTime;
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    filterAttrs
    foldlAttrs
    isAttrs
    listToAttrs
    mapAttrs
    # optionalAttrs
    ;
  inherit
    (lib.lists)
    concatMap
    elem
    filter
    findFirst
    foldl'
    # head
    length
    optionals
    toList
    uniqueStrings
    ;
  inherit
    (lib.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    isStringLike
    optionalString
    removePrefix
    removeSuffix
    splitString
    substring
    toLower
    typeOf
    ;
  inherit (lib.trivial) isFunction;
  inherit (paths) src libraries;

  typeAliases = {
    resolve = {
      #~@ Attrset
      "attrs" = "set";
      "attrset" = "set";
      "attrSet" = "set";
      "record" = "set";

      #~@ List
      "array" = "list";

      #~@ Lambda (Function)
      "fn" = "lambda";
      "fun" = "lambda";
      "func" = "lambda";
      "function" = "lambda";

      #~@ String
      "str" = "string";

      #~@ Integer
      "integer" = "int";
      "number" = "int";

      #~@ Boolean
      "boolean" = "bool";

      #~@ Float
      "double" = "float";
      "decimal" = "float";
    };

    display = mapAttrs (_: withArticle) {
      "set" = "attrset";
      "lambda" = "function";
      "int" = "integer";
      "float" = "float";
      "bool" = "boolean";
      "null" = "null";
      "list" = "list";
      "string" = "string";
      "path" = "path";
    };
  };

  withArticle = word:
    if word == "null"
    then "null"
    else let
      vowels = ["a" "e" "i" "o" "u"];
      firstLetter = toLower (substring 0 1 word);
    in
      if elem firstLetter vowels
      then "an ${word}"
      else "a ${word}";

  concatNonEmptyStrings = {
    sep ? " ",
    parts,
  }:
    concatStringsSep sep (
      filter
      (string: string != "")
      (toList parts)
    );

  foldModule = {
    type,
    name,
    aliases,
    module,
  }: let
    canonical = typeAliases.resolve.${type} or type;
    values =
      map
      (key: module.${key} or null)
      ((toList aliases) ++ [name]);
    present = filter (value: value != null) values;
  in
    if canonical == "string"
    then
      concatNonEmptyStrings {
        sep = "\n";
        parts =
          map (
            value:
              optionalString (value != null) (
                if isStringLike value
                then toString value
                else let
                  kind = typeOf value;
                in
                  throw "foldModule: '${name}' alias resolved to ${
                    typeAliases.display.${kind} or (withArticle kind)
                  }, expected string-like"
              )
          )
          values;
      }
    else if canonical == "set"
    then foldl' (a: b: a // b) {} present
    else if canonical == "list"
    then foldl' (a: b: a ++ b) [] present
    else
      throw "foldModule: unsupported type '${
        typeAliases.display.${type} or (withArticle type)
      }'";

  assertType = {
    type,
    name,
    value,
  }: let
    result = {
      actual = typeOf value;
      expected = typeAliases.resolve.${type} or type;
    };

    display = {
      actual =
        typeAliases.display.${result.actual} or
        (withArticle result.actual);
      expected =
        typeAliases.display.${result.expected} or
        (withArticle result.expected);
    };
  in
    if result.actual == result.expected
    then value
    else throw "${name}: expected ${display.expected}, got ${display.actual}";

  empty = {
    modules = {};
    rootAliases = {};
  };

  # -- Exclusion predicates ────────────────────────────────────────────────
  isExcludedDir = dir:
    elem dir exclusions.dirs
    || hasPrefix "." dir;

  isExcludedFile = file:
    elem file exclusions.files
    || (
      foldl'
      (acc: pat: acc || hasSuffix pat file)
      false
      exclusions.patterns
    );

  # -- Documentation discovery ─────────────────────────────────────────────
  findDocs = {
    dir,
    name,
  }: let
    mkRelativeDir = {
      root,
      stem,
    }:
      removePrefix (toString root + "/") (toString stem);

    mkDocDir = {nest ? "Documentation"}:
      src
      + "/${nest}/"
      + mkRelativeDir {inherit dir src;};

    candidates = [
      (dir + "/${name}.md")
      (dir + "/README.md")
      (dir + "/readme.md")
      (mkDocDir {nest = "docs";} + "/${name}.md")
      (mkDocDir {nest = "docs";} + "/README.md")
      (mkDocDir {nest = "docs";} + "/readme.md")
      (mkDocDir {} + "/${name}.md")
      (mkDocDir {} + "/README.md")
      (mkDocDir {} + "/readme.md")
    ];
    found =
      findFirst
      (path: path != null && pathExists (toString path))
      null
      candidates;
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

  # -- .nix file processor ─────────────────────────────────────────────────
  processNixFile = dir: pathPrefix: entryName: let
    meta = {
      name = removeSuffix ".nix" entryName;
      path = [env.library] ++ pathPrefix ++ [meta.name];
      file = dir + "/${entryName}";
      directory = removePrefix ((toString libraries) + "/") (toString dir);
      ref = concatStringsSep "." meta.path;
      raw = import meta.file;
    };

    keys = {
      docs = {
        type = "string";
        aliases = ["_doc" "__doc" "_docs"];
        name = "__docs";
      };
      tests = {
        type = "attrs";
        name = "__tests";
        aliases = ["_test" "__test" "_tests"];
      };
      rootAliases = {
        type = "attrs";
        name = "__rootAliases";
        aliases = ["_rootAlias" "__rootAlias" "_rootAliases"];
      };
    };

    imported =
      if isFunction meta.raw
      then
        assertType {
          type = "set";
          name = "Module ${entryName}";
          value = meta.raw (env
            // {
              module = meta;
              __modulePath = meta.path;
              __moduleFile = meta.file;
              __moduleName = meta.name;
              __moduleRef = meta.ref;
            });
        }
      else
        assertType {
          type = "set";
          name = "Module ${entryName} (raw)";
          value = meta.raw;
        };

    normalized =
      imported
      // listToAttrs (
        map (key: let
          group = keys.${key};
        in {
          name = group.name;
          value = foldModule (group // {module = imported;});
        }) (attrNames keys)
      );

    cleaned = let
      attrsToRemove = uniqueStrings (
        concatMap (group: group.aliases) (attrValues keys)
        ++ filter (hasPrefix "_") (attrNames normalized)
        ++ optionals (!runTests) ["__tests"]
      );
    in
      removeAttrs normalized attrsToRemove;

    aliases = normalized.__rootAliases;
  in {
    modules.${meta.name} = let
      module = {
        namespace = meta.path;
        name = meta.ref;
        path = meta.file;
        inherit (meta) directory;
        filename = entryName;
      };

      exports = filterAttrs (n: _: !(hasPrefix "__" n)) cleaned;

      docs = let
        mdDocs = findDocs {
          inherit dir;
          inherit (meta) name;
        };
        available = normalized ? __docs;
      in
        if mdDocs.available
        then mdDocs
        else if available
        then rec {
          inherit available;
          type = "string";
          source = concatStringsSep "." [meta.ref "__docs"];
          location = splitString "." source;
        }
        else {
          inherit available;
          type = "none";
        };

      tests = let
        available = normalized ? __tests;
      in
        if available
        then let
          results =
            foldlAttrs (
              acc: _: group:
                acc
                ++ (
                  optionals
                  (isAttrs group)
                  map (n: group.${n}) (attrNames group)
                )
            ) []
            cleaned.__tests;
          total = length results;
          passed = length (filter (t: t.passed or false) results);
          failed = total - passed;
        in {
          inherit
            available
            total
            passed
            failed
            ;
        }
        else {inherit available;};
    in
      cleaned
      // {
        __meta = {
          inherit aliases module docs tests;
          exports = attrNames exports;
          functions = attrNames (filterAttrs (_: isFunction) exports);
          values = attrNames (filterAttrs (_: value: !isFunction value) exports);
          timestamp = currentTime;
        };
      };
    rootAliases = aliases;
  };

  # -- Recursive directory scanner ─────────────────────────────────────────
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
        inherit (res) rootAliases;
      }
      else if entryType == "regular" && hasSuffix ".nix" entryName && !isExcludedFile entryName
      then processNixFile dir pathPrefix entryName
      else empty;

    processed = mapAttrs processEntry (readDir dir);
  in
    foldlAttrs (acc: _: v: {
      modules = acc.modules // v.modules;
      rootAliases = acc.rootAliases // v.rootAliases;
    })
    empty
    processed;
in
  scanDir
