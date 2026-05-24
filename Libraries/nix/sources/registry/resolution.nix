{_, ...}: let
  meta = let
    doc = ''
      Source registry resolution helpers.

      Turns paths or registry seed attrsets into canonical source records and
      provides flexible lookups across nested registry trees. The helpers here
      are intentionally generic so application-style and style-style registries
      can share the same source seeding and selection layer.

      Depends on: filesystem.importers.importRegistry, attrsets.access,
      lists.aggregation, lists.selection, lists.transformation,
      debug.assertions, types.predicates.
    '';

    exports = let
      internal = let
        functions = {
          inherit
            byNames
            lookup
            mkSource
            normalize
            ;
        };
        aliases = {
          lookupRegistry = lookup;
          mkRegistrySource = mkSource;
          normalizeRegistrySource = normalize;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        inherit
          lookup
          mkSource
          normalize
          ;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrByPath getAttr;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.lists.access) head tail;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) wrap;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.predicates) isAttrs isPath isList isString;

  /**
  Normalize a registry source specification into a canonical source record.

  Accepted inputs:
  - a path or string, treated as the registry root
  - an attrset containing `root`/`path` and optional overrides such as
    `name`, `stems`, `recursive`, `extraArgs`, `raw`, or `value`

  The returned record always contains:
  - `name`
  - `path`
  - `root`
  - `raw`
  - `value`
  - `stems`
  - `recursive`
  - `extraArgs`

  # Type
  ```nix
  mkSource :: any -> AttrSet
  ```
  */
  mkSource = value: let
    args =
      if isAttrs value
      then value
      else if isPath value || isString value
      then {path = value;}
      else
        assert withContext {
          name = "mkSource";
          context = "validating registry source value";
          assertion = false;
          message = "expected `value` to be a path, string, or attrset";
        }; null;

    root = args.root or (args.path or null);
    path = args.path or root;
    name =
      args.name or
      (
        if path != null
        then baseNameOf (toString path)
        else "registry"
      );
    stems = args.stems or ["data"];
    recursive = args.recursive or true;
    extraArgs = args.extraArgs or (args.args or {});
    raw =
      args.raw or
      (
        if root != null
        then
          importRegistry {
            inherit
              root
              stems
              recursive
              extraArgs
              ;
          }
        else args.value or {}
      );
    value' = args.value or raw;
  in {
    inherit
      extraArgs
      name
      path
      raw
      recursive
      root
      stems
      ;
    value = value';
  };

  /**
  Generic lookup helper for nested registry trees.

  When `path` is supplied, it is tried first. Otherwise `name`/`names` are
  expanded into single-segment lookup paths and tried in order until one
  resolves. Missing lookups fall back to `default`.

  # Type
  ```nix
  lookup :: {
    registry :: AttrSet,
    name? :: string,
    names? :: [string],
    path? :: [string] | string,
    paths? :: [[string]] | [string],
    default? :: any,
    caseInsensitive? :: bool,
  } -> any
  ```
  */
  lookup = args @ {
    registry,
    default ? null,
    name ? null,
    names ? [],
    path ? null,
    caseInsensitive ? false,
    ...
  }: let
    normalizeSegment = segment:
      if caseInsensitive && isString segment
      then toLowerCase segment
      else segment;

    lookupPath = current: remaining:
      if remaining == []
      then current
      else let
        segment = head remaining;
      in
        if isAttrs current && hasAttr segment current
        then lookupPath (getAttr segment current) (tail remaining)
        else default;

    candidateNames = unique (filter isString ((
        if name != null
        then [name]
        else []
      )
      ++ names));

    resolveNames = remaining:
      if remaining == []
      then default
      else let
        candidate = normalizeSegment (head remaining);
      in
        if isAttrs registry && hasAttr candidate registry
        then getAttr candidate registry
        else resolveNames (tail remaining);
  in
    if path != null
    then
      lookupPath registry (
        if isList path
        then map normalizeSegment path
        else [normalizeSegment path]
      )
    else resolveNames candidateNames;

  /**
  Lookup a list of registry names in order.

  # Type
  ```nix
  byNames :: { registry :: AttrSet, names :: [string], default? :: any } -> any
  ```
  */
  byNames = {
    registry,
    names,
    default ? null,
    caseInsensitive ? false,
    ...
  }:
    lookup {
      inherit
        caseInsensitive
        default
        names
        registry
        ;
    };

  /**
  Alias for `mkSource` so the public API reads more naturally.
  */
  normalize = value: mkSource value;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
