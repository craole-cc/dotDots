{
  config,
  lib,
  ...
}: let
  #| Module Parts
  top = "DOTS";
  dom = "lib";
  mod = "lists";
  alt = "dib";

  #| Native Imports
  inherit
    (lib)
    lessThan
    ;
  inherit
    (lib.lists)
    any
    flatten
    toList
    unique
    sort
    length
    elemAt
    ;
  inherit
    (lib.strings)
    filter
    match
    split
    stringLength
    substring
    hasPrefix
    hasInfix
    hasSuffix
    toLower
    toInt
    ;
  inherit (lib.options) mkOption;

  #| Module Imports
  cfg = config.${top}.${dom}.${mod};

  #| Module Options
  prep = mkOption {
    description = "Flattens a nested list structure into a single-level list, including all elements from inner lists. Non-list inputs are automatically converted to a list.";
    example = let
      input = [
        "a"
        [
          "b"
          ["c"]
        ]
      ];
      output = cfg.prep input;
    in {
      inherit input output;
    };

    default = let
      process = list: flatten (toList list);
    in
      list: process list;
  };

  blanks = mkOption {
    description = "Processes blank lines in a list. Identifies and filters empty strings, null values, and newline characters. Returns an attrset with the filtered list, inverted list (only blanks), total count, and test function.";
    example = let
      input = [
        "a"
        ""
        "b"
        "\n"
        "c"
      ];
      output = cfg.blanks input;
    in {
      inherit input output;
    };
    default = list: let
      list' = cfg.prep list;
      check = item: item == "" || item == null || hasPrefix "\n" item;
      inverted = filter (item: (check item)) list';
      filtered = filter (item: (!check item)) list';
      total = length filtered;
    in {
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
    description = "Removes lines that start with specified string(s). By default, filters common comment markers (#, //, <!--, /*, ```, '''). Returns an attrset with filtered results, matching lines, and helper functions.";
    example = let
      input = {
        target = ["#"];
        list = [
          "a"
          "#b"
          "c"
        ];
      };
      output = cfg.prefixed input;
    in {
      inherit input output;
    };
    default = {
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
    }: let
      #| Input
      list' = cfg.prep list;
      target' = cfg.prep target;

      #| Process
      check = item: targetList: any (target: hasPrefix target item) targetList;

      #| Output
      inverted = filter (item: (check item target')) list';
      filtered = filter (item: (!check item target')) list';
      total = length filtered;
    in {
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
    description = "Removes lines/paths that contain specified string(s). By default, filters paths containing '/review', '/tmp', or '/temp'. Returns an attrset with filtered results, matching lines, and helper functions.";
    example = let
      input = {
        target = ["/review"];
        list = [
          "a"
          "/review/b"
          "c"
        ];
      };
      output = cfg.infixed input;
    in {
      inherit input output;
    };
    default = {
      target ? [
        "/review"
        "/tmp"
        "/temp"
      ],
      list,
    }: let
      #| Input
      list' = cfg.prep list;
      target' = cfg.prep target;

      #| Processing
      check = item: targetList: any (target: hasInfix target item) targetList;

      #| Output
      inverted = filter (item: (check item target')) list';
      filtered = filter (item: (!check item target')) list';
      total = length filtered;
    in {
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
    description = "Removes lines that end with specified string(s). By default, filters paths ending with '.nix'. Returns an attrset with filtered results, matching lines, and helper functions.";
    default = {
      target ? ".nix",
      list,
    }: let
      #| Input
      list' = cfg.prep list;
      target' = cfg.prep target;

      #| Processing
      check = item: targetList: any (target: hasSuffix target item) targetList;

      #| Output
      inverted = filter (item: (check item target')) list';
      filtered = filter (item: (!check item target')) list';
      total = length filtered;
    in {
      inherit
        check
        filtered
        inverted
        total
        ;
      list = list';
      target = target';
    };
    example = let
      input = {
        target = ".nix";
        list = [
          "a"
          "b.nix"
          "c"
        ];
      };
      output = cfg.suffixed input;
    in {
      inherit input output;
    };
  };

  order = mkOption {
    description = "Takes a list of strings and returns them in sorted order, with proper handling of numeric values including percentages and decimals.";
    default = list: let
      #| Input
      list' = cfg.prep list;

      #| Processing
      #@ Function to remove leading zeros from numeric strings
      removeLeadingZeros = str: let
        #@ Match any number of leading zeros followed by remaining digits (or just "0")
        result = match "^0+([1-9][0-9]*)$|^0$" str;
      in
        if result == null
        then str
        else if result == []
        then "0" # ? This is just the string "0"
        else elemAt result 0; # ? The matched part without leading zeros

      #@ Convert percentage to decimal representation for comparison
      percentToDecimal = str: let
        #@ Remove the % sign
        numStr = substring 0 (stringLength str - 1) str;
        #@ Check if it already has a decimal point
        hasDecimal = match ".*\\.[0-9]*" numStr != null;
      in
        #@ Handle both whole number and decimal percentages
        if hasDecimal
        then let
          #@ Split by decimal point
          parts = split "\\." numStr;
          intPart = elemAt parts 0;
          decPart = elemAt parts 2;

          #@ Shift decimal point left by 2 places (e.g., 0.5% → 0.005)
          newDecPart = "${substring (stringLength intPart - 2) 2 intPart}${decPart}";
          newIntPart =
            if stringLength intPart <= 2
            then "0"
            else substring 0 (stringLength intPart - 2) intPart;
        in "${newIntPart}.${newDecPart}"
        else let
          #@ For whole numbers, divide by 100 (e.g., 15% → 0.15)
          num = toInt numStr;
          whole = num / 100;
          fraction = num - (whole * 100);

          #@ Ensure fractional part has leading zero if needed
          fractionStr =
            if fraction < 10
            then "0${toString fraction}"
            else toString fraction;
        in "${toString whole}.${fractionStr}";

      #@ Compare items for sorting
      compareItems = a: b: let
        #@ Check for different numeric formats
        isDecimalA = match "^[0-9]*\\.[0-9]+$" a != null;
        isDecimalB = match "^[0-9]*\\.[0-9]+$" b != null;
        isPercentA = match "^[0-9]+(\\.[0-9]+)?%$" a != null;
        isPercentB = match "^[0-9]+(\\.[0-9]+)?%$" b != null;
        isIntegerA = match "^[0-9]+$" a != null;
        isIntegerB = match "^[0-9]+$" b != null;

        #@ Convert to comparable string values
        valueA =
          if isPercentA
          then percentToDecimal a # ? Converts percentage to decimal (15% → 0.15)
          else if isDecimalA
          then a # ? Already in correct format
          else if isIntegerA
          then "${toString (toInt (removeLeadingZeros a))}.0" # ? Add .0 to integers for proper comparison
          else a;

        valueB =
          if isPercentB
          then percentToDecimal b
          else if isDecimalB
          then b
          else if isIntegerB
          then "${toString (toInt (removeLeadingZeros b))}.0"
          else b;

        #? Classification flags for comparison logic
        isNumericA = isDecimalA || isPercentA || isIntegerA;
        isNumericB = isDecimalB || isPercentB || isIntegerB;

        #? Case-insensitive string comparison preparation
        lowerA = toLower a;
        lowerB = toLower b;
      in
        if isNumericA && isNumericB
        then
          #@ Compare numeric values via their string representations
          lessThan valueA valueB
        else if isNumericA
        then
          #@ Numbers always come before non-numeric strings
          true
        else if isNumericB
        then
          #@ Non-numeric strings always come after numbers
          false
        else if lowerA != lowerB
        then
          #@ Case-insensitive comparison for different strings
          lessThan lowerA lowerB
        else
          #@ If lowercase versions are equal, uppercase comes first
          lessThan a b;

      #| Output
      ordered = sort compareItems list';
    in
      ordered;
    example = let
      input = [
        "B"
        "11"
        "02"
        "a"
        "bullseye"
        "bullsEye"
        "b"
        "target"
        "Targeted"
        "c"
        "C"
        "0.1"
        "0.2"
        "15%"
        "050"
        "005"
        "01"
        "100"
        "10"
      ];
      output = cfg.order input;
    in {
      inherit input output;
    };
  };

  prune = mkOption {
    description = "Comprehensive list cleaning function that removes blank lines, null values, comments, duplicates, and sorts the result. Combines multiple list operations into a single utility.";
    default = list: let
      prepped = (cfg.blanks list).filtered;
      sorted = cfg.order prepped;
      pruned = unique (cfg.prefixed {list = sorted;}).filtered;
    in
      pruned;
    example = let
      input = [
        "b"
        ""
        "#comment"
        "a"
        "a"
      ];
      output = cfg.prune input;
    in {
      inherit input output;
    };
  };

  tests = mkOption {
    description = ''Tests for ${cfg.name}'';
    default = let
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
        "0.25"
        "22%"
        "0.1"
        "40%"
        "2"
        "090"
        "005"
        "3"
      ];

      nestedList = [
        "craole"
        "Coldplay"
        ["Chris Martin"]
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
    in {
      prep = cfg.prep list;
      prune = cfg.prune list;
      order = cfg.order list;
      blanks = cfg.blanks list;
      prefixed = cfg.prefixed {inherit list;};
      infixed = cfg.infixed {inherit list;};
      suffixed = cfg.suffixed {inherit list;};
    };
  };

  #| Module Exports
  exports = {
    inherit
      prep
      prune
      order
      blanks
      prefixed
      infixed
      suffixed
      ;
  };
in {
  options = {
    ${top}.${dom}.${mod} =
      exports
      // {
        inherit tests;
      };
    ${alt} = exports;
  };
}
