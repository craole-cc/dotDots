{
  lib,
  _,
  ...
}: let
  inherit (lib.lists) all any filter isList map;
  inherit (lib.attrsets) mapAttrs;
  inherit
    (lib.strings)
    concatStringsSep
    hasInfix
    hasPrefix
    hasSuffix
    removePrefix
    removeSuffix
    replaceStrings
    splitString
    ;
  inherit (_.trivial.empty) isEmpty isNotEmpty;
  inherit (_.filesystem.predicates) normalizeFlakePath;

  /**
  Convert a single string, or list of strings, into a cleaned list.

  Removes null values but preserves empty strings.

  # Type
  toList :: string | [string | null] | null -> [string]

  # Examples
  toList "foo"               # ["foo"]
  toList ["foo" null "bar"]  # ["foo" "bar"]
  toList null                # []
  */
  toList = value:
    filter (v: v != null) (lib.lists.toList value);

  # Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  # Internal: build a predicate that checks if any pattern matches any input value.
  _mkAnyPredicate = checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    any (p: any (v: checker p v) vs) ps;

  # Internal: build a predicate that requires ALL inputs to match at least one pattern.
  _mkAllPredicate = checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    all (v: any (p: checker p v) ps) vs;

  /**
  Check whether any pattern is contained in any input string.

  Accepts either a single string or a list of strings for both arguments.

  # Type
  contains :: string | [string] -> string | [string] -> bool

  # Examples
  contains "foo" "foobar"           # true
  contains ["foo" "bar"] "foobar"   # true
  contains "foo" ["baz" "foobar"]   # true
  contains ["foo" "bar"] ["baz"]    # false
  */
  /**
  Check whether ALL input strings contain at least one of the given patterns.

  # Type
  containsAll :: string | [string] -> string | [string] -> bool

  # Examples
  containsAll "foo" ["foobar" "fooX"]  # true  — every input has "foo"
  containsAll "foo" ["foobar" "baz"]   # false — "baz" doesn't contain "foo"
  */
  inherit
    (mapAttrs (_: _mkAnyPredicate) {
      contains = hasInfix;
      startsWith = hasPrefix;
      endsWith = hasSuffix;
    })
    contains
    startsWith
    endsWith
    ;

  inherit
    (mapAttrs (_: _mkAllPredicate) {
      containsAll = hasInfix;
      startsWithAll = hasPrefix;
      endsWithAll = hasSuffix;
    })
    containsAll
    startsWithAll
    endsWithAll
    ;

  /**
  Concatenate a list of strings, or groups of strings, with a delimiter.

  # Type
  concat :: string -> [string] | [[string]] -> string | [string]

  # Examples
  concat "," ["a" "b" "c"]          # "a,b,c"
  concat "," [["a" "b"] ["c" "d"]]  # ["a,b" "c,d"]
  */
  concat = delimiter: input:
    if (input == null) || (input == [])
    then ""
    else if isList (builtins.head input)
    then map (group: concatStringsSep delimiter group) input
    else concatStringsSep delimiter input;

  /**
  Remove leading occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space. Strips repeatedly.

  # Type
  trimStart :: string | null -> string | [string] -> string | [string]

  # Examples
  trimStart null "  foo bar"              # "foo bar"
  trimStart "home:" "home:home:Pictures" # "Pictures"
  trimStart null ["  a" "  b"]           # ["a" "b"]
  */
  trimStart = chars: let
    c =
      if chars == null
      then " "
      else chars;
    go = s:
      if hasPrefix c s
      then go (removePrefix c s)
      else s;
  in
    _applyStr go;

  /**
  Remove trailing occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space. Strips repeatedly.

  # Type
  trimEnd :: string | null -> string | [string] -> string | [string]

  # Examples
  trimEnd null "foo bar  "   # "foo bar"
  trimEnd "!" "foo!!!"       # "foo"
  trimEnd null ["a  " "b "] # ["a" "b"]
  */
  trimEnd = chars: let
    c =
      if chars == null
      then " "
      else chars;
    go = s:
      if hasSuffix c s
      then go (removeSuffix c s)
      else s;
  in
    _applyStr go;

  /**
  Remove leading and trailing occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space.

  # Type
  trim :: string | null -> string | [string] -> string | [string]

  # Examples
  trim null "  foo bar  "       # "foo bar"
  trim "/" "/foo/bar/"          # "foo/bar"
  trim null ["  a  " "  b  "]  # ["a" "b"]
  */
  trim = chars: input:
    trimStart chars (trimEnd chars input);

  /**
  Convert a string or list of strings to lower case.

  # Type
  toLower :: string | [string] -> string | [string]

  # Examples
  toLower "FOO Bar"      # "foo bar"
  toLower ["FOO" "BAR"] # ["foo" "bar"]
  */
  toLower = _applyStr lib.strings.toLower;

  /**
  Convert a string or list of strings to upper case.

  # Type
  toUpper :: string | [string] -> string | [string]

  # Examples
  toUpper "foo bar"      # "FOO BAR"
  toUpper ["foo" "bar"] # ["FOO" "BAR"]
  */
  toUpper = _applyStr lib.strings.toUpper;

  /**
  Replace all occurrences of substrings in a string or list of strings.

  Accepts either a single search/replace pair, or parallel lists.

  # Type
  replaceAll :: string | [string] -> string | [string] -> string | [string] -> string | [string]

  # Examples
  replaceAll "foo" "bar" "foo foo"               # "bar bar"
  replaceAll [" " "_"] ["-" "-"] "zen twilight"  # "zen-twilight"
  replaceAll "a" "b" ["a" "cat"]                 # ["b" "cbt"]
  */
  replaceAll = search: replace: let
    ss = toList search;
    rs = toList replace;
  in
    _applyStr (replaceStrings ss rs);

  /**
  Normalize an application or identifier name for fuzzy matching.

  Converts to lower case and replaces spaces/underscores with hyphens.

  # Type
  normalizeName :: string | null -> string | null

  # Examples
  normalizeName "Zen Twilight"  # "zen-twilight"
  normalizeName "zen_twilight"  # "zen-twilight"
  normalizeName null            # null
  */
  normalizeName = value:
    if (value == null) || (value == [])
    then null
    else replaceAll [" " "_"] ["-" "-"] (lib.strings.toLower value);

  /**
  Normalize a single name or list of names for fuzzy matching.

  # Type
  normalizeNames :: string | [string | null] | null -> string | [string | null] | null

  # Examples
  normalizeNames "Zen Twilight"               # "zen-twilight"
  normalizeNames ["Zen Twilight" "zen_beta"]  # ["zen-twilight" "zen-beta"]
  normalizeNames null                         # null
  */
  normalizeNames = values:
    if (values == null) || (values == [])
    then null
    else if isList values
    then map normalizeName values
    else normalizeName values;

  /**
  Split a string or list of strings by a delimiter.

  # Type
  split :: string -> string | [string] -> [string] | [[string]]

  # Examples
  split "," "a,b,c"        # ["a" "b" "c"]
  split "," ["a,b" "c,d"]  # [["a" "b"] ["c" "d"]]
  */
  split = delimiter:
    _applyStr (splitString delimiter);
in {
  inherit
    concat
    contains
    containsAll
    endsWith
    endsWithAll
    isEmpty
    isNotEmpty
    normalizeName
    normalizeNames
    normalizeFlakePath
    replaceAll
    split
    startsWith
    startsWithAll
    toLower
    toUpper
    trim
    trimEnd
    trimStart
    ;
}
