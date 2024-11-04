{ config, lib, ... }:
let
  mod = "lists";

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
  options.dot.libraries.${mod} = with config.dot.libraries.${mod}; {
    prep =
      let
        process = list: flatten (toList list);
      in
      mkOption {
        description = "Converts to a list, if it isn't already, then flattens it.";
        default = list: process list;
      };

    prune =
      let
        process = list: (blanks (prefixed { inherit list; }).inverted).inverted;
      in
      mkOption {
        description = "Removes comments, null values, and duplicates from a list.";
        default = list: unique (process list);
      };

    order =
      let
        check = a: b: lessThan (toLower a) (toLower b);
      in
      mkOption {
        description = "Sorts alphanumerically and case-insensitively.";
        default = list: sort check (prep list);
      };

    clean =
      let
        process = list: order (prune list);
      in
      mkOption {
        description = "Removes comments, null values, and duplicates then sorts alphanumerically.";
        default = list: process list;
      };

    blanks =
      let
        check = item: item == "" || item == null || hasPrefix "\n" item;
      in
      mkOption {
        description = "Process blank lines in a list";
        default =
          list:
          let
            list' = prep list;
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
        check = item: targetList: any (target: hasPrefix target item) targetList;
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
            filtered = filter (item: (check item target')) list';
            inverted = filter (item: (!check item target')) list';
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
        check = item: targetList: any (target: hasInfix target item) targetList;
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
            filtered = filter (item: (check item target')) list';
            inverted = filter (item: (!check item target')) list';
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
        check = item: targetList: any (target: hasSuffix target item) targetList;
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
            filtered = filter (item: (check item target')) list';
            inverted = filter (item: (!check item target')) list';
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
          clean = clean list;
          prune = prune list;
          order = order list;
          blanks = blanks list;
          prefixed = prefixed { inherit list; };
          infixed = infixed { inherit list; };
          suffixed = suffixed { inherit list; };
          nix =
            let
              ignore = [
                #| Settings
                ".env"
                ".envrc"
                ".git"
                ".github"
                ".gitlab"
                ".gitignore"
                ".vscode"
                ".sops.yaml"
                ".ignore"

                #| Project
                "LICENSE"
                "README"
                "bin"

                #| Nix
                "default.nix"
                "flake.nix"
                "flake.lock"
                "shell.nix"
                "package.nix"
                "options.nix"
                "config.nix"
                "modules.nix"
                "module.nix"

                #| Temporary
                "review"
                "tmp"
                "temp"
                "result"
                ".Trash-1000"
              ];

              infixedList =
                (infixed {
                  list = fileList;
                  target = map (p: "/" + p + "/") ignore;
                }).inverted;

              suffixedList =
                path:
                clean
                  (suffixed {
                    list =
                      (infixed {
                        list = path;
                        target = map (p: "/" + p + "/") ignore;
                      }).inverted;
                    target = map (p: "/" + p) ignore;
                  }).inverted;
              #   (infixed {
              #     list = fileList;
              #     target = map (p: "/" + p + "/") ignore;
              #   }).inverted;

              # suffixedList =
              #   (suffixed {
              #     list = infixedList;
              #     target = map (p: "/" + p) ignore;
              #   }).inverted;
              finalList =
                path:
                clean
                  (suffixed {
                    list =
                      (infixed {
                        list = path;
                        target = map (p: "/" + p + "/") ignore;
                      }).inverted;
                    target = map (p: "/" + p) ignore;
                  }).inverted;
            in
            finalList fileList;
          # path: finalList path;
          # // suffixed {
          #   list = fileList;
          #   target = map (p: "/" + p) ignore;
          # };
        };
      };
  };
}
