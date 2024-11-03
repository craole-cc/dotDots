{ lib, ... }:
let
  #| Native
  inherit (lib) filter lessThan;
  inherit (lib.lists)
    any
    flatten
    toList
    unique
    sort
    length
    head
    last
    ;
  inherit (lib.strings)
    hasPrefix
    hasInfix
    hasSuffix
    toLower
    ;

  /**
    prep :: [a] -> [a]

    Flattens a nested list structure or string into a single list.

    Type: [a] -> [a]
    Example:
      prep [ "a" ["b" ["c"]] ]
      => [ "a" "b" "c" ]
  */
  prep =
    let
      process = _list: flatten (toList _list);
    in
    _list: process _list;

  /**
    blanks :: [String] -> AttrSet

    Removes blank lines in a list and provides filtering statistics.

    Parameters:
      _list = List of strings to process

    Returns: AttrSet
      check    = Function to test if an item is blank
      filtered = List with blank lines removed
      inverted = List containing only blank lines
      total    = Count of non-blank lines
      list     = Original list after preprocessing

    Example:
      blanks [ "a" "" "b" "\n" ]
      => {
        filtered = [ "a" "b" ];
        inverted = [ "" "\n" ];
        total = 2;
        ...
      }
  */
  blanks =
    let
      check = _item: _item == "" || _item == null || hasPrefix "\n" _item;
    in
    _list:
    let
      list' = prep _list;
      inverted = filter (item: (check item)) list';
      filtered = filter (item: (!check item)) list';
      total = length filtered;
    in
    {
      inherit
        check
        filtered
        inverted
        total
        ;
      list = list';
    };

  /**
    prefixed :: AttrSet -> AttrSet

    Removes lines that start with specified string(s).

    Parameters:
      target = Optional list of prefixes to filter. Defaults to common comment markers
      list   = List of strings to process

    Returns: AttrSet
      check    = Function to test if an item has any target prefix
      filtered = List with prefixed lines removed
      inverted = List containing only prefixed lines
      total    = Count of prefixed lines
      list     = Original list after preprocessing
      target   = Processed target list

    Example:
      prefixed {
        target = [ "#" ];
        list = [ "a" "#b" "c" ];
      }
      => {
        filtered = [ "a" "c" ];
        inverted = [ "#b" ];
        ...
      }
  */
  prefixed =
    let
      check = _item: _targetList: any (_target: hasPrefix _target _item) _targetList;
    in
    {
      target ? [
        # Single-line comments
        "#"
        "//"
        "<!--"

        # Multi-line comments.
        "/*"
        "```"
        "'''"
      ],
      list,
    }:
    let
      list' = prep list;
      target' = prep target;
      inverted = filter (_item: (check _item target')) list';
      filtered = filter (_item: (!check _item target')) list';
      total = length inverted;
    in
    {
      inherit
        check
        filtered
        inverted
        total
        ;
      list = list';
      target = target';
    };

  /**
    infixed :: AttrSet -> AttrSet

    Removes lines that contain specified string(s).

    Parameters:
      target = Optional list of substrings to filter. Defaults to ["/review" "/tmp" "/temp"]
      list   = List of strings to process

    Returns: AttrSet
      check    = Function to test if an item contains any target string
      filtered = List with matching lines removed
      inverted = List containing only matching lines
      total    = Count of matching lines
      list     = Original list after preprocessing
      target   = Processed target list
  */
  infixed =
    let
      check = _item: _targetList: any (_target: hasInfix _target _item) _targetList;
    in
    {
      target ? [
        "/review"
        "/tmp"
        "/temp"
      ],
      list,
    }:
    let
      list' = prep list;
      target' = prep target;
      inverted = filter (_item: (check _item target')) list';
      filtered = filter (_item: (!check _item target')) list';
      total = length inverted;
    in
    {
      inherit
        check
        filtered
        inverted
        total
        ;
      list = list';
      target = target';
    };

  /**
    suffixed :: AttrSet -> AttrSet

    Removes lines that end with specified string(s).

    Parameters:
      list   = List of strings to process
      target = Optional suffix or list of suffixes. Defaults to ".nix"

    Returns: AttrSet
      check    = Function to test if an item ends with any target suffix
      filtered = List with matching lines removed
      inverted = List containing only matching lines
      total    = Count of matching lines
      list     = Original list after preprocessing
      target   = Processed target list
  */
  suffixed =
    let
      check = _item: _targetList: any (_target: hasSuffix _target _item) _targetList;
    in
    {
      target ? ".nix",
      list,
    }:
    let
      list' = prep list;
      target' = prep target;
      inverted = filter (_item: (check _item target')) list';
      filtered = filter (_item: (!check _item target')) list';
      total = length inverted;
    in
    {
      inherit
        check
        filtered
        inverted
        total
        ;
      list = list';
      target = target';
    };

  /**
    order :: [String] -> [String]

    Sorts alphanumerically and case-insensitively.

    Example:
      order [ "B" "a" "C" ]
      => [ "a" "B" "C" ]
  */
  order =
    let
      check = _a: _b: lessThan (toLower _a) (toLower _b);
    in
    _list: sort check (prep _list);

  /**
    prune :: [String] -> [String]

    Comprehensive list cleaning function that:
    1. Removes blank lines and null values
    2. Removes comments (lines starting with # or //)
    3. Removes duplicates
    4. Sorts the result

    Example:
      prune [ "b" "" "#comment" "a" "a" ]
      => [ "a" "b" ]
  */
  prune =
    _list:
    let
      prepped = (blanks _list).filtered;
      sorted = order prepped;
      pruned = unique (prefixed { list = sorted; }).filtered;
    in
    pruned;

  /**
    tests :: AttrSet

    Comprehensive test suite for the lists library.
    Tests all main functions with various types of input data:
    - Basic lists (strings, numbers, duplicates, blank lines)
    - Nested lists (arrays within arrays)
    - Lists with various comment styles
    - File system paths

    Returns: AttrSet of test results for each function
  */
  tests =
    let
      basicList = [
        "grapes"
        ""
        "apples"
        "oranges"
        "900"
        "bananas"
        "bananas"
        "bananas"
        "10"
        "10"
        "10"
        "

            "
        "pineapples"
        "pineapples"
        "pineapples"
        "pears"
        ""
        "20"
        "01"
        "2"
        "3"
      ];

      nestedList = [
        "craole"
        "Coldplay"
        [ "Chris Martin" ]
        "The Fugees"
        [
          "Pras"
          "Wycliff"
          "Lauryn Hill"
        ]
        "Bob Marley & The Wailers"
        [
          "Bob Marley"
          "Peter Tosh"
          "Bunny Wailer"
        ]
      ];

      prefixedList = [
        "grapes"
        ""
        "#900"
        "bananas"
        "10"
        "// pineapples"
        "// pears"
        ""
        "<!-- This is a valid HTML comment. It has a dash followed by a string of hyphens (20) and then an end tag. It is commonly used for sectioning off content within an HTML document. -->"
        "01"
        "2"
        "/*
              --------------------------------------------------------------------------------
                  |	CSS COMMENT START
              --------------------------------------------------------------------------------
            */"
      ];

      fileList = [
        "/dots/.envrc"
        "/dots/.git"
        "/dots/.github"
        "/dots/.gitignore"
        "/dots/src/configurations/host/review/victus/victus.nix"
        "/dots/src/configurations/host/review/victus/victus.nix"
        "/dots/src/configurations/host/review/victus/victus.nix"
        "/dots/.sops.yaml"
        "/dots/.vscode"
        "/dots/src/configurations/host/review/victus/default.nix"
        "/dots/LICENSE"
        "/dots/README"
        "/dots/src/configurations/host/review/dbooktoo/hardware-configuration.nix"
        "/dots/bin"
        "/dots/src/configurations/host/pop/lol.nix"
        "/dots/default.nix"
        "/dots/flake.lock"
        "/dots/flake.nix"
        "/dots/src"
        "/dots/src/configurations/host/dbook"
        "/dots/src/configurations/host/dbook"
        "/dots/src/configurations/user/review/default.failed.nix"
        "/dots/src/configurations/host/dbook"
        "/dots/src/configurations/host/nixos"
        "/dots/src/configurations/host/dbook/default.nix"
        "/dots/src/configurations/host/dbook/hardware-configuration.nix"
        "/dots/src/configurations/host/default.nix"
        "/dots/src/configurations/host/module.nix"
        "/dots/src/configurations/user/default.nix"
        "/dots/src/configurations/host/nixos/default.nix"
        "/dots/src/configurations/user/craole/default.nix"
        "/dots/src/configurations/host/options.nix"
        "/dots/src/configurations/host/review/dbooktoo/default.nix"
        "/dots/src/configurations/host/testing.nix"
        "/dots/src/configurations/host/temp/testing.nix"
        "/dots/src/configurations/user/craole"
        "/dots/src/configurations/user/qyatt/default copy.nix"
        "/dots/src/configurations/user/qyatt/default.nix"
        "/dots/src/configurations/user/review/craole.bac.nix"
      ];

      list = basicList ++ nestedList ++ prefixedList ++ fileList;

      assertions =
        let
          ascertain =
            actual: expected:
            ascertainCount actual.count expected.count
            && ascertainPosition "first" actual.first expected.first
            && ascertainPosition "last" actual.last expected.last;

          ascertainCount =
            actual: expected:
            assert
              (actual == expected) || throw "Expected ${toString expected} items but got ${toString actual}";
            true;

          ascertainPosition =
            position: actual: expected:
            assert
              (actual == expected)
              || throw "Expected ${toString position} item to be '${expected}' but got '${actual}'";
            true;

        in
        {
          blanks =
            let
              result = blanks list;
              actual = result.total;
              expected = 78;
              passed = ascertainCount actual expected;
            in
            {
              inherit result passed;
            };

          prep =
            let
              result = prep list;
              actual = {
                count = length result;
                first = head result;
                last = last result;
              };
              expected = {
                count = 83;
                first = "grapes";
                last = "/dots/src/configurations/user/review/craole.bac.nix";
              };
              passed = ascertain actual expected;
            in
            {
              inherit result passed;
            };

          order =
            let
              result = order list;
              actual = {
                count = length result;
                first = head result;
                last = last result;
              };
              expected = {
                count = 83;
                first = "";
                last = "Wycliff";
              };
              passed = ascertain actual expected;
            in
            {
              inherit result passed;
            };

          prune =
            let
              result = prune list;
              actual = {
                count = length result;
                first = head result;
                last = last result;
              };
              expected = {
                count = 58;
                first = "/dots/.envrc";
                last = "Wycliff";
              };
              passed = ascertain actual expected;
            in
            {
              inherit result passed;
            };

          infixed =
            let
              result = infixed { inherit list; };
              actual = result.total;
              expected = 9;
              passed = ascertainCount actual expected;
            in
            {
              inherit result passed;
            };

          prefixed =
            let
              result = prefixed { inherit list; };
              actual = result.total;
              expected = 5;
              passed = ascertainCount actual expected;
            in
            {
              inherit result passed;
            };

          suffixed =
            let
              result = suffixed { inherit list; };
              actual = result.total;
              expected = 23;
              passed = ascertainCount actual expected;
            in
            {
              inherit result passed;
            };

        };
    in
    {
      inherit (assertions)
        blanks
        prep
        order
        prune
        infixed
        prefixed
        suffixed
        ;
    };

in
{
  lists = {
    inherit
      prep
      blanks
      order
      prune
      infixed
      prefixed
      suffixed
      tests
      ;
  };
}
