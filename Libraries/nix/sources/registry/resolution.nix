{_, ...}: let
  meta = let
    # TODO: Update the doc
    doc = ''
      Style registry data (Layer 0).

      Provides normalized style records from `./data`, with consistent
      `categories` fields. Supplies primitive tree inspection for recursive
      processing, validated registry lookup, registry-derived identification
      metadata, and shared resolution helpers used by higher style layers.

      Depends on: sources.registry.importer.
    '';
    exports = let
      internal = let
        functions = {
          inherit mkSource normalize;
        };
        aliases = {
          normalizeEntry = normalize;
        };
      in
        {inherit functions aliases;} // functions // aliases;
      external = {
        mkRegistyrySource = mkSource;
        normalizeRegistryEntry = normalize;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) wrap;
  inherit (_.strings.predicates) isValidPosixName;
  inherit (_.types.predicates) isAttrs isPath isString;

  #TODO: Add the nix-style documentation with headings input, return, dependencies, type and examples
  mkSource = value: let
    args =
      if isAttrs value
      then value
      else if isPath value || isString value
      then {path = value;}
      else
        assert withContext {
          name = "mkSource";
          context = "validating mkSource value";
          assertion = false;
          message = "expected `value` to be a path, string, or attrset";
        }; null;

    owner = args.owner or "mkSource";
    recursive = args.recursive or true;
    extraArgs = args.extraArgs or (args.args or {});

    path = let
      path' = args.root or (args.path or null);
    in
      assert withContext {
        name = owner;
        context = concat " " ["resolving" "source" "path"];
        assertion = path' != null;
        message = concat " " [
          "expected either"
          (wrap ["root" "path"])
          "to be provided"
        ];
      }; path';

    name = let
      name' = args.name or (baseNameOf path);
    in
      assert withContext {
        name = owner;
        context = concat " " ["resolving" "source" "name"];
        assertion = isString name' && isValidPosixName name';
        message = concat " " [
          "expected source name to be a valid POSIX name,"
          "got"
          (wrap name')
        ];
      }; name';

    raw = let
      raw' = importRegistry {inherit path recursive extraArgs;};
    in
      assert withContext {
        name = owner;
        context = concat " " ["importing" "registry" "source"];
        assertion = isNotEmpty raw';
        message = concat " " [
          "expected"
          (wrap "importRegistry")
          "to return a non-empty attrset for"
          (wrap name)
        ];
      }; raw';
  in {inherit path name raw;};

  # TODO: Add the nix-style documentation with headings input, return, dependencies, type and examples
  # TODO: Implement normalizeEntry for single-entry field coercion
  normalize = {};
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
