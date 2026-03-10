{
  __libraryPath,
  _,
  lib,
  ...
}: let
  _debug = mkModuleDebug __libraryPath;

  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (_.types.predicates) isList isString;
  inherit (lib.lists) all any filter head map;
  inherit (lib.strings) concatStringsSep splitString;

  /**
  Convert a single string, or list of strings, into a cleaned list.

  Removes null values but preserves empty strings.

  # Type
  ```nix
  toList :: string | [string | null] | null -> [string]
  ```

  # Examples
  ```nix
  toList "foo"               # => ["foo"]
  toList ["foo" null "bar"]  # => ["foo" "bar"]
  toList null                # => []
  ```
  */
  toList = value:
    filter (v: v != null) (lib.lists.toList value);

  /**
  Concatenate a list of strings, or groups of strings, with a delimiter.

  # Type
  ```nix
  concat :: string -> [string] | [[string]] -> string | [string]
  ```

  # Examples
  ```nix
  concat "," ["a" "b" "c"]          # => "a,b,c"
  concat "," [["a" "b"] ["c" "d"]]  # => ["a,b" "c,d"]
  ```
  */
  concat = delimiter: input:
    if !(isString delimiter)
    then
      throw (_debug.withLoc {
        function = "concat";
        message = "delimiter must be a string";
        input = delimiter;
      })
    else if (input == null) || (input == [])
    then ""
    else if isList (head input)
    then map (group: concatStringsSep delimiter group) input
    else concatStringsSep delimiter input;

  /**
  Split a string or list of strings by a delimiter.

  # Type
  ```nix
  split :: string -> string | [string] -> [string] | [[string]]
  ```

  # Examples
  ```nix
  split "," "a,b,c"        # => ["a" "b" "c"]
  split "," ["a,b" "c,d"]  # => [["a" "b"] ["c" "d"]]
  ```
  */
  split = delimiter: input:
    if !(isString delimiter)
    then
      throw (_debug.withLoc {
        function = "split";
        message = "delimiter must be a string";
        input = delimiter;
      })
    else if isList input && any isList input
    then let
      function = "split";
      message = "nested lists are not supported";
      signature = "string -> string | [string] -> [string] | [[string]]";
      example = mkExample {
        cmd = ''split "," ["a,b" "c,d"]'';
        res = ''[["a" "b"] ["c" "d"]]'';
      };
    in
      throw (_debug.withDoc {inherit input function message signature example;})
    else if isList input
    then map (splitString delimiter) input
    else splitString delimiter input;

  # Internal: build a predicate that checks if any pattern matches any input value.
  mkAnyPredicate = {
    function,
    checker,
    patterns,
    input,
  }: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (_debug.withDoc {
        inherit function;
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${function} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else any (p: any (v: checker p v) vs) ps;

  # Internal: build a predicate that requires ALL inputs to match at least one pattern.
  mkAllPredicate = {
    function,
    checker,
    patterns,
    input,
  }: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (_debug.withDoc {
        inherit function;
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${function} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else all (v: any (p: checker p v) ps) vs;

  exports = {
    inherit
      concat
      split
      toList
      mkAnyPredicate
      mkAllPredicate
      ;
  };
in
  exports
  // {
    _rootAliases = {
      concatStrings = concat;
      splitString = split;
      stringToList = toList;
      mkAnyStringPredicate = mkAnyPredicate;
      mkAllStringPredicate = mkAllPredicate;
    };

    _tests = runTests {
      toList = {
        singleString = mkTest {
          desired = ["foo"];
          command = ''toList "foo"'';
          outcome = toList "foo";
        };
        listWithNull = mkTest {
          desired = ["foo" "bar"];
          command = ''toList ["foo" null "bar"]'';
          outcome = toList ["foo" null "bar"];
        };
        nullInput = mkTest {
          desired = [];
          command = "toList null";
          outcome = toList null;
        };
      };
      concat = {
        simpleList = mkTest {
          desired = "a,b,c";
          command = ''concat "," ["a" "b" "c"]'';
          outcome = concat "," ["a" "b" "c"];
        };
        nestedLists = mkTest {
          desired = ["a,b" "c,d"];
          command = ''concat "," [["a" "b"] ["c" "d"]]'';
          outcome = concat "," [["a" "b"] ["c" "d"]];
        };
        emptyInput = mkTest {
          desired = "";
          command = ''concat "," []'';
          outcome = concat "," [];
        };
        nullInput = mkTest {
          desired = "";
          command = ''concat "," null'';
          outcome = concat "," null;
        };
      };
      split = {
        singleString = mkTest {
          desired = ["a" "b" "c"];
          command = ''split "," "a,b,c"'';
          outcome = split "," "a,b,c";
        };
        listOfStrings = mkTest {
          desired = [["a" "b"] ["c" "d"]];
          command = ''split "," ["a,b" "c,d"]'';
          outcome = split "," ["a,b" "c,d"];
        };
      };
    };
  }
