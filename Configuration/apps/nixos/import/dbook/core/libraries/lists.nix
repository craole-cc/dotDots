{
  config,
  lib,
  ...
}:
let
  #| Native Imports
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
  inherit (lib.options) mkOption;

  #| Extended Imports
  inherit (config) DOTS;

  base = "lib";
  mod = "lists";
  cfg = DOTS.${base}.${mod};

  inherit (cfg)
    prep
    blanks
    order
    prefixed
    ;
in
{
  options.DOTS.${base}.${mod} = {
    prep = mkOption {
      /**
        prep :: [a] -> [a]

        Flattens a nested list structure or string into a single list.

        Type: [a] -> [a]
        Example:
          prep [ "a" ["b" ["c"]] ]
          => [ "a" "b" "c" ]
      */
      description = "Converts to a list, if it isn't already, then flattens it.";
      example = [
        "a"
        [
          "b"
          [ "c" ]
        ]
      ];
      default =
        let
          process = list: flatten (toList list);
        in
        list: process list;
    };

    blanks = mkOption {
      /**
        blanks :: [String] -> AttrSet

        Removes blank lines in a list and provides filtering statistics.

        Parameters:
          list = List of strings to process

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
      description = ''
        Process blank lines in a list.

        Parameters:
          list = List of strings to process

        Returns: AttrSet
          check    = Function to test if an item is blank
          filtered = List with blank lines removed
          inverted = List containing only blank lines
          total    = Count of non-blank lines
          list     = Original list after preprocessing

        Example:
          blanks [ "a" "" "b" "c" "\n" ]
          => {
            filtered = [ "a" "b" "c" ];
            inverted = [ "" "\n" ];
            total = 2;
            ...
          }
      '';
      example = [
        "a"
        ""
        "b"
        "c"
        "\n"
      ];
      default =
        list:
        let
          list' = prep list;
          check = item: item == "" || item == null || hasPrefix "\n" item;
          filtered = filter (item: (check item)) list';
          inverted = filter (item: (!check item)) list';
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
    };

    prefixed = mkOption {
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
      description = ''
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
            total = 2;
            ...
          }
        }
      '';
      default =
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
          #| Input
          list' = prep list;
          target' = prep target;

          #| Processing
          check = item: targetList: any (target: hasPrefix target item) targetList;

          #| Output
          inverted = filter (item: (check item target')) list';
          filtered = filter (item: (!check item target')) list';
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
          target = target';
        };
    };

    infixed = mkOption {
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

        Example:
          infixed {
            target = [ "/review" "/tmp" "/temp" ];
            list = [ "a" "/review/b" "c" ];
          }
          => {
            filtered = [ "a" "c" ];
            inverted = [ "/review/b" ];
            total = 2;
            ...
          }
      */
      description = ''
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

        Example:
          infixed {
            target = [ "/review" "/tmp" "/temp" ];
            list = [ "a" "/review/b" "c" ];
          }
          => {
            filtered = [ "a" "c" ];
            inverted = [ "/review/b" ];
            total = 2;
            ...
          }
      '';
      default =
        {
          target ? [
            "/review"
            "/tmp"
            "/temp"
          ],
          list,
        }:
        let
          #| Input
          list' = prep list;
          target' = prep target;

          #| Processing
          check = item: targetList: any (target: hasInfix target item) targetList;

          #| Output
          inverted = filter (item: (check item target')) list';
          filtered = filter (item: (!check item target')) list';
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
          target = target';
        };
    };

    suffixed = mkOption {
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

        Example:
          suffixed {
            target = ".nix";
            list = [ "a" "b.nix" "c" ];
          }
          => {
            filtered = [ "a" "c" ];
            inverted = [ "b.nix" ];
            total = 2;
            ...
          }
      */
      description = ''
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

        Example:
          suffixed {
            target = ".nix";
            list = [ "a" "b.nix" "c" ];
          }
          => {
            filtered = [ "a" "c" ];
            inverted = [ "b.nix" ];
            total = 2;
            ...
          }
      '';
      default =
        {
          target ? ".nix",
          list,
        }:
        let
          #| Input
          list' = prep list;
          target' = prep target;

          #| Processing
          check = item: targetList: any (target: hasSuffix target item) targetList;

          #| Output
          inverted = filter (item: (check item target')) list';
          filtered = filter (item: (!check item target')) list';
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
          target = target';
        };
    };

    order = mkOption {
      /**
        order :: [String] -> [String]

        Sorts alphanumerically and case-insensitively.

        Parameters:
          list = List of strings to process

        Returns:
          list = Sorted list of strings

        Example:
          order [ "B" "a" "C" ]
          => [ "a" "B" "C" ]
      */
      description = ''
        Sorts alphanumerically and case-insensitively.

        Parameters:
          list = List of strings to process

        Returns:
          list = Sorted list of strings

        Example:
          order [ "B" "a" "C" ]
          => [ "a" "B" "C" ]
      '';
      default =
        let
          check = a: b: lessThan (toLower a) (toLower b);
        in
        list: sort check (prep list);
    };

    prune = mkOption {
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
      description = ''
        Comprehensive list cleaning function that:
        1. Removes blank lines and null values
        2. Removes comments (lines starting with # or //)
        3. Removes duplicates
        4. Sorts the result

        Example:
          prune [ "b" "" "#comment" "a" "a" ]
          => [ "a" "b" ]
      '';
      default =
        list:
        let
          prepped = (blanks list).filtered;
          sorted = order prepped;
          pruned = unique (prefixed { list = sorted; }).filtered;
        in
        pruned;
    };

    tests = mkOption {
      description = "Tests for {{base}}.{{mod}}";
      default =
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
        in
        with cfg;
        {
          prep = prep list;
          prune = prune list;
          clean = clean list;
          order = order list;
          blanks = blanks list;
          prefixed = prefixed { inherit list; };
          infixed = infixed { inherit list; };
          suffixed = suffixed { inherit list; };
        };
    };
  };
}
