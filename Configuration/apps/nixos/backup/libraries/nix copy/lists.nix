{ config, lib, ... }:
let
  #| Internal Libraries
  inherit (config.DOTS) Libraries;

  mod = "lists";
  cfg = Libraries.${mod};

  #| External Libraries
  inherit (lib) filter lessThan;
  inherit (lib.options) mkOption;
  inherit (lib.lists)
    any
    flatten
    toList
    unique
    sort
    length
    ;
  inherit (lib.strings)
    hasPrefix
    hasInfix
    hasSuffix
    toLower
    ;
in
{
  options.DOTS.Libraries.${mod} = with cfg; {
    prep =
      let
        process = _list: flatten (toList _list);
      in
      mkOption {
        description = "Converts to a list, if it isn't already, then flattens it.";
        default = _list: process _list;
      };

    prune =
      let
        process = _list: (blanks (prefixed { list = _list; }).inverted).inverted;
      in
      mkOption {
        description = "Removes comments, null values, and duplicates from a list.";
        default = _list: unique (process _list);
      };

    order =
      let
        check = _a: _b: lessThan (toLower _a) (toLower _b);
      in
      mkOption {
        description = "Sorts alphanumerically and case-insensitively.";
        default = _list: sort check (prep _list);
      };

    clean =
      let
        process = _list: order (prune _list);
      in
      mkOption {
        description = "Removes comments, null values, and duplicates then sorts alphanumerically.";
        default = _list: process _list;
      };

    blanks =
      let
        check = _item: _item == "" || _item == null || hasPrefix "\n" _item;
      in
      mkOption {
        description = "Process blank lines in a list";
        default =
          _list:
          let
            list' = prep _list;
            filtered = filter (item: (check item)) list';
            inverted = filter (item: (!check item)) list';
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
          };
      };

    prefixed =
      let
        check = _item: _targetList: any (_target: hasPrefix _target _item) _targetList;
      in
      mkOption {
        description = "Removes lines that start with the specified string(s)";
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
            list' = prep list;
            target' = prep target;
            filtered = filter (_item: (check _item target')) list';
            inverted = filter (_item: (!check _item target')) list';
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

    infixed =
      let
        check = _item: _targetList: any (_target: hasInfix _target _item) _targetList;
      in
      mkOption {
        description = "Removes lines that contain the specified string(s)";
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
            list' = prep list;
            target' = prep target;
            filtered = filter (_item: (check _item target')) list';
            inverted = filter (_item: (!check _item target')) list';
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

    suffixed =
      let
        check = _item: _targetList: any (_target: hasSuffix _target _item) _targetList;
      in
      mkOption {
        description = "Removes lines that end with the specified string(s)";
        default =
          {
            target ? ".nix",
            list,
          }:
          let
            list' = prep list;
            target' = prep target;
            filtered = filter (_item: (check _item target')) list';
            inverted = filter (_item: (!check _item target')) list';
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

    test =
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
      mkOption {
        description = "Tests the lists libs";
        default = {
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
