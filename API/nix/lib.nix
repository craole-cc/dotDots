rec {
  inherit
    (builtins)
    any
    attrNames
    concatMap
    concatStringsSep
    elem
    filter
    hashString
    head
    isAttrs
    isList
    isPath
    isString
    listToAttrs
    mapAttrs
    match
    pathExists
    readDir
    sort
    substring
    tail
    ;

  /**
  Deduplicates items in a list without external lib dependencies
  */
  unique = list: let
    acc = list: seen:
      if list == []
      then seen
      else let
        x = head list;
        xs = tail list;
      in
        if elem x seen
        then acc xs seen
        else acc xs (seen ++ [x]);
  in
    acc list [];

  /**
  Safely splits a dot-separated string into a list of keys
  */
  splitPathString = str: let
    matches = match "([^.]*)\\.(.*)" str;
  in
    if matches == null
    then
      if str == ""
      then []
      else [str]
    else [(head matches)] ++ splitPathString (head (tail matches));

  /**
  Resolves a path (list or dot-string) against an attribute set
  */
  getByPath = path: set: let
    resolve = list: current:
      if list == []
      then current
      else if isAttrs current && current ? ${head list}
      then resolve (tail list) current.${head list}
      else null;
  in
    resolve (
      if isList path
      then path
      else if isString path
      then splitPathString path
      else throw "getByPath: path must be a list or a dot-separated string"
    )
    set;

  /**
  Recursively extracts all paths to leaf values in a nested attribute set.

  # Arguments
  - `set` {attrs}
  : nested attribute set to traverse

  # Returns
  {list<list<string>>}
  : list of path lists, where each path is a list of keys leading to a leaf value (non-attribute or empty attribute set)

  # Example
    extractPaths { a.b.c = 1; a.d = 2; e = 3; }
    # Returns: [["a" "b" "c"] ["a" "d"] ["e"]]
  */
  extractPaths = set:
    concatMap (
      key: let
        val = set.${key};
      in
        if isAttrs val && val != {}
        then map (p: [key] ++ p) (extractPaths val)
        else [[key]]
    ) (attrNames set);

  /**
  Checks whether prefixList is a prefix of targetList.
  */
  hasPrefix = prefixList: targetList:
    if prefixList == []
    then true
    else if targetList == []
    then false
    else if head prefixList == head targetList
    then hasPrefix (tail prefixList) (tail targetList)
    else false;

  /**
  Checks if two paths overlap (i.e. one is a parent, child, or exact match of the other).
  */
  isPathOverlapping = firstPath: secondPath:
    hasPrefix firstPath secondPath
    || hasPrefix secondPath firstPath;

  /**
  Converts a path list to a dot-separated string representation.

  # Arguments
  - `path` {list<string>|string}
  : path as a list of keys or a string

  # Returns
  {string}
  : dot-separated string representation of the path

  # Example
    formatPath ["a" "b" "c"]
    # Returns: "a.b.c"
  */
  formatPath = path:
    if isList path
    then concatStringsSep "." path
    else path;

  /**
  Recursive deep merge without allocating temporary sets for key scanning
  */
  mergeAttrs = set1: set2:
    if isAttrs set1 && isAttrs set2
    then let
      keys = unique (attrNames set1 ++ attrNames set2);
    in
      listToAttrs (
        map (key: {
          name = key;
          value =
            if set1 ? ${key} && set2 ? ${key}
            then mergeAttrs set1.${key} set2.${key}
            else if set2 ? ${key}
            then set2.${key}
            else set1.${key};
        })
        keys
      )
    else set2;

  /**
  Filters an attribute set using a predicate function (pred name value)
  */
  filterAttrs = pred: set:
    listToAttrs (
      concatMap (
        name:
          if pred name set.${name}
          then [
            {
              name = name;
              value = set.${name};
            }
          ]
          else []
      ) (attrNames set)
    );

  isHiddenPath = name: match "^\\..*" name != null;
  isNixFile = name: type:
    type
    == "regular"
    && name != "default.nix"
    && match ".*\\.nix$" name != null;
  isNixDirectory = dir: name: type:
    (type == "directory")
    && pathExists (dir + "/${name}/default.nix");

  importAttrs = {
    target,
    required ? [],
    defaults ? {},
  }:
    if !isPath target
    then throw "importAttrs: home must be a path"
    else
      mapAttrs
      (
        filename: type: let
          imported = let
            name = let
              matched = match "(.*)\\.nix" filename;
            in
              if type == "regular" && matched != null
              then head matched
              else filename;

            id = substring 0 8 (hashString "sha256" name);
          in
            mergeAttrs
            {inherit name id;}
            (import (target + "/${filename}"));

          merged = mergeAttrs defaults imported;

          keys = rec {
            inherit required;
            missing =
              filter
              (path: getByPath path merged == null)
              required;
            defined = extractPaths imported;
            derived =
              filter
              (default:
                !(
                  any
                  (derived: isPathOverlapping default derived)
                  defined
                ))
              (extractPaths defaults);
            overall = unique (defined ++ derived);
            catalog = concatStringsSep "\n" (
              sort
              (a: b: a < b)
              (map formatPath overall)
            );
          };
        in
          if keys.missing != []
          then
            throw "'${merged.name}' is missing required attributes: ${
              concatStringsSep ", " (
                map
                (path: "${merged.name}.${formatPath path}")
                keys.missing
              )
            }"
          else
            merged
            // {keys = removeAttrs keys ["required" "missing"];}
      )
      (
        filterAttrs (
          name: type:
            !isHiddenPath name
            && (isNixFile name type || isNixDirectory target name type)
        ) (readDir target)
      );
}
