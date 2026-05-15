{
  _,
  src,
  ...
}: let
  __doc = ''
    Input Source Resolution

    Parses the raw flake to extract, normalize, and categorize its inputs.
    It maps arbitrarily named external flake inputs to a canonical internal
    format to ensure downstream derivations are predictable.

    Also provides lock file predicates for querying persisted input metadata
    purely, without evaluating the flake.
  '';
  functions = {inherit lockFileHas;};
  __exports = {
    internal = functions;
    external = functions;
  };

  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.filesystem.access) readFile;
  inherit (_.filesystem.resolution) getFlake;
  inherit (_.lists.predicates) any;
  inherit (_.attrsets.access) attrValues;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.construction) fromJSON;

  /**
  Checks whether any input in a flake lock file matches a given field/value.

  Reads the lock file purely (no flake evaluation) and searches all nodes
  for a match. Supports exact and fuzzy (infix) matching.

  # Type
  ```nix
  lockFileHas :: { path? :: Path, field :: String, value :: String, fuzzy? :: Bool } -> Bool
  ```

  # Examples
  ```nix
  lockFileHas { field = "owner"; value = "numtide"; }
  # => true (if any input is owned by numtide)

  lockFileHas { field = "repo"; value = "treefmt"; fuzzy = true; }
  # => true (if any input repo contains "treefmt")

  lockFileHas { path = /my/flake; field = "owner"; value = "numtide"; }
  # => true (checks a specific flake path)
  ```
  */
  lockFileHas = {
    path ? src,
    field,
    value,
    fuzzy ? false,
  }: let
    lock = fromJSON (readFile (path + "/flake.lock"));
    nodes = attrValues lock.nodes;
    matches = v:
      if fuzzy
      then hasInfix value v
      else v == value;
  in
    any (n: matches ((n.locked or {}).${field} or "")) nodes;
in
  __exports.internal
  // {
    inherit __doc;
    __rootAliases = __exports.external;
  }
