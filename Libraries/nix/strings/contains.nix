{lib, ...}: let
  inherit (lib.attrsets) isAttrs;
  inherit (lib.lists) any isList;
  inherit (lib.strings) hasInfix toLower;

  # ---------------------------------------------------------------------------
  # mkAny
  # ---------------------------------------------------------------------------
  /**
  Fan-out checker — returns true if ANY pattern matches ANY input string.

  # Arguments

  - `checker`: `string -> string -> bool` — comparison function
  - `patterns`: `string | [string]`
  - `input`: `string | [string]`
  */
  mkAny = {
    checker,
    patterns,
    input,
  }: let
    patternsList =
      if isList patterns
      then patterns
      else [patterns];
    inputList =
      if isList input
      then input
      else [input];
    checkPattern = pattern: any (str: checker pattern str) inputList;
  in
    any checkPattern patternsList;

  # ---------------------------------------------------------------------------
  # mkChecker
  # ---------------------------------------------------------------------------
  /**
  Builds the string comparison function respecting the `caseSensitive` flag.

  When `caseSensitive = false` (default), both sides are lowercased before
  calling `hasInfix`. When `caseSensitive = true`, strings are compared as-is.

  # Arguments

  - `caseSensitive`: `bool`

  # Returns

  `string -> string -> bool`
  */
  mkChecker = caseSensitive: let
    normalize = s:
      if caseSensitive
      then s
      else toLower s;
  in
    pattern: str: hasInfix (normalize pattern) (normalize str);

  # ---------------------------------------------------------------------------
  # contains
  # ---------------------------------------------------------------------------
  /**
  Check whether any pattern is contained in any input string.

  Accepts either a single string or a list of strings for both `patterns`
  and `input`. Matching is **case-insensitive by default**; pass
  `caseSensitive = true` to enforce exact case matching.

  Supports three calling styles:

  - **Curried**: `contains patterns input`
  - **Options prefix**: `contains { caseSensitive = true; } patterns input`
  - **Attrset**: `contains { patterns = ...; input = ...; caseSensitive? = ...; }`

  # Type

  ```
  contains
    :: { patterns      :: string | [string]
        , input         :: string | [string]
        , caseSensitive :: bool               # default: false
        }
    -> bool

  contains
    :: (string | [string] | { caseSensitive :: bool })
    -> (string | [string])
    -> bool
  ```

  # Examples

  ```nix
  # Curried (case-insensitive by default)
  contains "foo" "FOOBAR"             # => true
  contains ["foo" "bar"] "FOOBAR"     # => true
  contains "foo" ["baz" "FOOBAR"]     # => true
  contains ["foo" "bar"] ["baz"]      # => false

  # Options prefix
  contains { caseSensitive = true; } "foo" "FOOBAR"   # => false
  contains { caseSensitive = true; } "FOO" "FOOBAR"   # => true

  # Attrset
  contains { patterns = "foo"; input = "FOOBAR"; }    # => true
  contains {
    patterns      = ["foo" "bar"];
    input         = ["baz" "FOOBAR"];
    caseSensitive = true;
  }                                                   # => false
  ```
  */
  contains = patternsOrAttrs: inputOrPatterns: let
    # --- Detect call style --------------------------------------------------
    isAttrsetCall =
      isAttrs patternsOrAttrs
      && patternsOrAttrs ? patterns
      && patternsOrAttrs ? input;

    isOptsCall =
      isAttrs patternsOrAttrs
      && !(patternsOrAttrs ? patterns)
      && !(patternsOrAttrs ? input);

    # --- Resolve case sensitivity -------------------------------------------
    caseSensitive =
      if isAttrsetCall || isOptsCall
      then patternsOrAttrs.caseSensitive or false
      else false;

    checker = mkChecker caseSensitive;
  in
    if isAttrsetCall
    then
      # Style: contains { patterns = ...; input = ...; caseSensitive? = ...; }
      mkAny {
        inherit checker;
        patterns = patternsOrAttrs.patterns;
        input = patternsOrAttrs.input;
      }
    else if isOptsCall
    then
      # Style: contains { caseSensitive = true; } patterns input
      # inputOrPatterns holds `patterns` at this point; waiting for actual input
      (actualInput:
        mkAny {
          inherit checker;
          patterns = inputOrPatterns;
          input = actualInput;
        })
    else
      # Style: contains patterns input  (plain curried)
      mkAny {
        inherit checker;
        patterns = patternsOrAttrs;
        input = inputOrPatterns;
      };
in {
  inherit contains;
}
