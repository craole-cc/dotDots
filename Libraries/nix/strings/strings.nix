{
  __moduleRef,
  _,
  ...
}: let
  exports = {
    inherit
      concat
      fromBool
      split
      toList
      mkAnyPredicate
      mkAllPredicate
      indentedList
      indentedForError
      toDomainName
      ;
  };

  _debug = mkModuleDebug __moduleRef;

  inherit (_.debug.format) mkExample;
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) filter;
  inherit (_.lists.predicates) all any isIn;
  inherit (_.types.predicates) isAttrs isBool isFunction isList isString;
  inherit (_.strings.construction) concatStringsSep splitString splitStringBy;
  inherit (_.strings.transformation) indent;
  toListOrig = _.lists.construction.toList;

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
  toList = value: filter (v: v != null) (toListOrig value);

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
      throw (
        _debug.withLoc {
          function = "concat";
          message = "delimiter must be a string";
          input = delimiter;
        }
      )
    else if (input == null) || (input == [])
    then ""
    else if isList (head input)
    then map (group: concatStringsSep delimiter group) input
    else concatStringsSep delimiter input;

  /**
    Split a string or list of strings by one or more delimiters, with optional
    retention of matched delimiter characters in the output.

    Accepts three calling conventions:

    **Attrset (friendly):**
  ```nix
    split {
      delimiters = "." | ["."] | (prev: curr: ...);
      include    = false | true | "." | ["."] | (prev: curr: ...);
      input      = "..." | ["..." "..."];
    }
  ```

    **Shorthand string (drop-in for old API):**
  ```nix
    split "." "foo.bar.baz"
    split "." ["foo.bar" "baz.qux"]
  ```

    **Curried (raw, drop-in for `splitStringBy`):**
  ```nix
    split predicate include input
  ```

    In attrset mode, `delimiters` may be a string, list of strings, or a raw
    predicate function. When a raw predicate function is passed, `include` must
    also be a bool or raw predicate function — mixing a function delimiter with a
    string/list include throws an error.

    Empty strings produced by leading, trailing, or consecutive delimiters are
    filtered from the result.

    # Inputs

    `delimiters` (attrset) / `delimiter` (string) / `predicate` (curried)
    : 1. What to split on. One of:
         - `string` — single delimiter character or sequence
         - `[string]` — list of delimiter characters or sequences
         - `function` — raw `prev: curr: bool` predicate (curried mode always uses this form)

    `include` (attrset / curried)
    : 2. Which delimiter characters to retain at the start of the next chunk. One of:
         - `false` — discard all delimiters (default; implied by string shorthand)
         - `true` — retain all delimiters
         - `string` — retain only this delimiter
         - `[string]` — retain only these delimiters
         - `function` — raw `prev: curr: bool` predicate

         When `delimiters` is a function, `include` must be `true`, `false`, or a function.

    `input`
    : 3. String or list of strings. Nested lists throw an error.

    # Return

    If `input` is a string: `[string]`.
    If `input` is a list of strings: `[[string]]`.

    Empty strings are always filtered from each result.

    # Dependencies

    - `_.strings.construction.splitStringBy`
    - `_.types.predicates.isString`
    - `_.types.predicates.isList`
    - `_.lists.predicates.any`
    - `_.lists.construction.filter`

    # Type
  ```nix
    # Attrset form
    split :: {
      delimiters :: string | [string] | (string -> string -> bool);
      include    :: bool | string | [string] | (string -> string -> bool);
      input      :: string | [string];
    } -> [string] | [[string]]

    # Shorthand string form (include = false)
    split :: string -> string | [string] -> [string] | [[string]]

    # Curried form (splitStringBy drop-in)
    split :: (string -> string -> bool) -> bool -> string | [string] -> [string] | [[string]]
  ```

    # Examples
  ```nix
    # Shorthand string form
    split "." "foo.bar.baz"
    # => [ "foo" "bar" "baz" ]

    split "." [ "foo.bar" "baz.qux" ]
    # => [ [ "foo" "bar" ] [ "baz" "qux" ] ]

    # Single delimiter, discard it
    split { delimiters = "."; include = false; input = "foo.bar.baz"; }
    # => [ "foo" "bar" "baz" ]

    # Multiple delimiters, discard all
    split { delimiters = ["." "-"]; include = false; input = "foo.bar-baz"; }
    # => [ "foo" "bar" "baz" ]

    # Multiple delimiters, retain only "."
    split { delimiters = ["." "-"]; include = "."; input = "foo.bar-baz"; }
    # => [ "foo" ".bar" "baz" ]

    # Multiple delimiters, retain all
    split { delimiters = ["." "-"]; include = true; input = "foo.bar-baz"; }
    # => [ "foo" ".bar" "-baz" ]

    # List of strings input
    split { delimiters = "."; include = false; input = [ "foo.bar" "baz.qux" ]; }
    # => [ [ "foo" "bar" ] [ "baz" "qux" ] ]

    # List input with retain
    split { delimiters = ["." "-"]; include = "."; input = [ "foo.bar" "baz-qux" ]; }
    # => [ [ "foo" ".bar" ] [ "baz" "qux" ] ]

    # Raw predicate delimiter with bool include (attrset)
    split {
      delimiters = (prev: curr: builtins.elem curr [ "." "-" ]);
      include    = false;
      input      = "foo.bar-baz";
    }
    # => [ "foo" "bar" "baz" ]

    # camelCase split via raw predicate
    split {
      delimiters = (prev: curr:
        builtins.match "[a-z]" prev != null &&
        builtins.match "[A-Z]" curr != null
      );
      include = true;
      input   = "fooBarBaz";
    }
    # => [ "foo" "Bar" "Baz" ]

    # Leading/trailing delimiters — empty strings are filtered
    split { delimiters = "."; include = false; input = ".foo.bar."; }
    # => [ "foo" "bar" ]

    # Curried form — drop-in for splitStringBy
    split (prev: curr: builtins.elem curr [ "." "-" ]) false "foo.bar-baz"
    # => [ "foo" "bar" "baz" ]
  ```
  */
  split = let
    mkPredicate = type: input:
      if type == "delimiters"
      #> Build a split predicate from a string or list of strings
      then _prev: delimiters: isIn delimiters (toList input)
      else if type == "includes"
      #> Build a retain predicate from bool, string, list, or function
      then
        if isBool input
        then _: _: input
        else if isString input
        then _: delim: delim == input
        else if isList input
        then _: delim: isIn delim input
        else input
      else throw "";

    #> Run splitStringBy and strip empty strings
    splitOne = predicate: keepSplit: str:
      filter
      (x: x != null && x != "")
      (splitStringBy predicate keepSplit str);

    #> Shared inner logic once predicates are resolved
    process = delimiters: include: input:
      if isList input && any isList input
      then let
        function = "split";
        message = "nested lists are not supported";
        signature = "{ delimiters :: string | [string] | fn; include :: bool | string | [string] | fn; input :: string | [string]; } -> [string] | [[string]]";
        example = mkExample {
          cmd = ''split { delimiters = "."; include = false; input = [ "foo.bar" "baz.qux" ]; }'';
          res = ''[ [ "foo" "bar" ] [ "baz" "qux" ] ]'';
        };
      in
        throw (_debug.withDoc {
          inherit input function message signature example;
        })
      else if isList input
      then map (splitOne delimiters include) input
      else splitOne delimiters include input;
  in
    arg:
    # Attrset form
      if isAttrs arg
      then let
        inherit (arg) input;
        delimiters = arg.delimiters or ".";
        includes = arg.include or false;
      in
        if (isFunction delimiters) && (isString includes || isList includes)
        then
          throw (_debug.withDoc {
            function = "split";
            message = "when `delimiters` is a function, `include` must be a bool or function, not a string or list";
            input = includes;
            signature = "{ delimiters :: fn; include :: bool | fn; input :: string | [string]; } -> [string] | [[string]]";
            example = mkExample {
              cmd = ''split { delimiters = (prev: curr: curr == "."); include = false; input = "foo.bar"; }'';
              res = ''[ "foo" "bar" ]'';
            };
          })
        else
          process
          (
            if isFunction delimiters
            then delimiters
            else mkPredicate "delimiters" delimiters
          )
          (mkPredicate "includes" includes)
          input
      # Curried form — raw predicate, drop-in for splitStringBy
      else if isFunction arg
      then
        include: input:
          if !(isBool include || isFunction include)
          then
            throw (_debug.withLoc {
              function = "split";
              message = "curried form: second argument (include) must be a bool or function";
              input = include;
            })
          else process arg (mkPredicate "includes" include) input
      # Shorthand string form — split "delimiter" input (include = false)
      else if isString arg
      then input: process (mkPredicate "delimiters" arg) (mkPredicate "includes" false) input
      # Bad first argument
      else
        throw (_debug.withLoc {
          function = "split";
          message = "first argument must be an attrset { delimiters, include, input }, a predicate function, or a delimiter string";
          input = arg;
        });

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
      throw (
        _debug.withDoc {
          inherit function;
          message = "patterns must be a string or list of strings";
          signature = "string | [string] -> string | [string] -> bool";
          input = patterns;
          example = mkExample {
            cmd = ''${function} "foo" ["bar" "baz"]'';
            res = "true";
          };
        }
      )
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
      throw (
        _debug.withDoc {
          inherit function;
          message = "patterns must be a string or list of strings";
          signature = "string | [string] -> string | [string] -> bool";
          input = patterns;
          example = mkExample {
            cmd = ''${function} "foo" ["bar" "baz"]'';
            res = "true";
          };
        }
      )
    else all (v: any (p: checker p v) ps) vs;

  indentedList = {
    items,
    title ? null,
    size ? 2,
    bullet ? "-",
  }:
    if title != null
    then "\n${indent size}${title}:\n${concat "\n" (map (i: "${indent (size + 2)}${bullet} ${i}") items)}"
    else "\n${concat "\n" (map (i: "${indent size}${bullet} ${i}") items)}";

  indentedForError = {
    items,
    title ? null,
    size ? 8,
    bullet ? "-",
  }:
    indentedList {
      inherit
        items
        title
        size
        bullet
        ;
    };

  /**
  Render a boolean as a lowercase string.

  # Type
  ```nix
  fromBool :: bool -> string
  ```

  # Examples
  ```nix
  fromBool true   # => "true"
  fromBool false  # => "false"
  ```
  */
  fromBool = value:
    if value
    then "true"
    else "false";

  toDomainName = domain:
    {
      themes = "theme";
      cursors = "cursor";
      icons = "icon";
      accents = "accent";
      flavors = "flavor";
    }.${
      domain
    } or domain;
in
  exports
  // {
    __rootAliases = {
      boolToString = fromBool;
      concatStrings = concat;
      splitString = split;
      stringToList = toList;
      mkAnyStringPredicate = mkAnyPredicate;
      mkAllStringPredicate = mkAllPredicate;
    };

    __tests = runTests {
      toList = {
        singleString = mkTest {
          desired = ["foo"];
          command = ''toList "foo"'';
          outcome = toList "foo";
        };
        listWithNull = mkTest {
          desired = [
            "foo"
            "bar"
          ];
          command = ''toList ["foo" null "bar"]'';
          outcome = toList [
            "foo"
            null
            "bar"
          ];
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
          outcome = concat "," [
            "a"
            "b"
            "c"
          ];
        };
        nestedLists = mkTest {
          desired = [
            "a,b"
            "c,d"
          ];
          command = ''concat "," [["a" "b"] ["c" "d"]]'';
          outcome = concat "," [
            [
              "a"
              "b"
            ]
            [
              "c"
              "d"
            ]
          ];
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
          desired = [
            "a"
            "b"
            "c"
          ];
          command = ''split "," "a,b,c"'';
          outcome = split "," "a,b,c";
        };
        listOfStrings = mkTest {
          desired = [
            [
              "a"
              "b"
            ]
            [
              "c"
              "d"
            ]
          ];
          command = ''split "," ["a,b" "c,d"]'';
          outcome = split "," [
            "a,b"
            "c,d"
          ];
        };
        attrsetMultipleDelimiters = mkTest {
          desired = [
            "foo"
            "bar"
            "baz"
          ];
          command = ''split { delimiters = ["." "-"]; include = false; input = "foo.bar-baz"; }'';
          outcome = split {
            delimiters = [
              "."
              "-"
            ];
            include = false;
            input = "foo.bar-baz";
          };
        };
        attrsetRetainDelimiter = mkTest {
          desired = [
            "foo"
            ".bar"
            "baz"
          ];
          command = ''split { delimiters = ["." "-"]; include = "."; input = "foo.bar-baz"; }'';
          outcome = split {
            delimiters = [
              "."
              "-"
            ];
            include = ".";
            input = "foo.bar-baz";
          };
        };
        attrsetLeadingTrailing = mkTest {
          desired = [
            "foo"
            "bar"
          ];
          command = ''split { delimiters = "."; include = false; input = ".foo.bar."; }'';
          outcome = split {
            delimiters = ".";
            include = false;
            input = ".foo.bar.";
          };
        };
      };
    };
  }
