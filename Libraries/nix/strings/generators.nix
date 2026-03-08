{
  lib,
  _,
  ...
}: let
  inherit (lib.lists) isList filter map;
  inherit (lib.strings) concatStringsSep splitString;
  inherit (_.trivial.tests) mkTest runTests;

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
    if (input == null) || (input == [])
    then ""
    else if isList (builtins.head input)
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
    if isList input
    then map (splitString delimiter) input
    else splitString delimiter input;
in {
  inherit
    concat
    split
    toList
    ;

  _tests = runTests {
    toList = {
      singleString = mkTest {
        desired = ["foo"];
        outcome = toList "foo";
      };
      listWithNull = mkTest {
        desired = ["foo" "bar"];
        outcome = toList ["foo" null "bar"];
      };
      nullInput = mkTest {
        desired = [];
        outcome = toList null;
      };
    };
    concat = {
      simpleList = mkTest {
        desired = "a,b,c";
        outcome = concat "," ["a" "b" "c"];
      };
      nestedLists = mkTest {
        desired = ["a,b" "c,d"];
        outcome = concat "," [["a" "b"] ["c" "d"]];
      };
      emptyInput = mkTest {
        desired = "";
        outcome = concat "," [];
      };
      nullInput = mkTest {
        desired = "";
        outcome = concat "," null;
      };
    };
    split = {
      singleString = mkTest {
        desired = ["a" "b" "c"];
        outcome = split "," "a,b,c";
      };
      listOfStrings = mkTest {
        desired = [["a" "b"] ["c" "d"]];
        outcome = split "," ["a,b" "c,d"];
      };
    };
  };
}
