{
  _,
  paths,
  ...
}: let
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) intersectAttrs recursiveUpdate;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.filesystem.traversal) importAllPaths;
  inherit (_.attrsets.construction) optionalAttrs nameValuePair;
  inherit (_.attrsets.transformation) mapAttrs';
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.predicates) all elem;
  inherit (_.filesystem.construction) concatPath mkTree;
  inherit (_.schema.construction) mkSchema;
  inherit (_.lists.transformation) filter;
  inherit (_.strings.construction) concat;

  schema = mkSchema {api = paths.repo.api.default.store;};
  repositoryPaths = recursiveUpdate (mkTree {
    inherit (schema.paths) roots stems;
  }) paths;

  args = {
    inherit _;
    inherit (_.attrsets.transformation) mapAttrs mapAttrsToList;
    inherit (_.filesystem.access) readFile;
    inherit (_.strings.transformation) replaceStrings;
    inherit mkPath mkAlias mkLayeredAlias mkAliasFamily mergeDisjoint mkSource importAllPaths importMerged;
  };

  importMerged = path:
    mergeDisjoint
    (map (file: import file args)
      (importAllPaths path).value);

  mkPath = {
    root,
    stem,
  }:
    concatPath {
      root = (foldl' (attrs: segment: attrs.${segment}) repositoryPaths.repo root).store;
      inherit stem;
    };

  mkAlias = command: {
    args ? [],
    description ? null,
    after ? [],
    pipe ? [],
  }:
    {
      cmd = [command] ++ args;
      inherit description;
    }
    // optionalAttrs (isNotEmpty after) {inherit after;}
    // optionalAttrs (isNotEmpty pipe) {inherit pipe;};

  #? Layers carry args, an optional trailing list (always placed last), and a description.
  mkLayeredAlias = command: baseLayers: layers: let
    allLayers = baseLayers ++ layers;
  in
    mkAlias command {
      args =
        concatMap (layer: layer.args or []) allLayers
        ++ concatMap (layer: layer.trailing or []) allLayers;
      description = concat ", " (
        filter (text: text != null)
        (map (layer: layer.description or null) allLayers)
      );
    };

  #? mkAliasFamily "chmod" {R = {...}; x = {...};} yields chmodR and chmodx.
  mkAliasFamily = command: variants: let
    prefix = variants.aliasPrefix or command;
    specs = removeAttrs variants ["aliasPrefix"];
  in
    mapAttrs' (
      suffix: spec:
        nameValuePair (prefix + suffix) (mkAlias command spec)
    )
    specs;

  #? Throws on a repeated alias name instead of silently keeping the last one.
  mergeDisjoint = attrsets:
    foldl' (merged: next: let
      clashing = attrNames (intersectAttrs merged next);
    in
      if clashing == []
      then merged // next
      else throw "duplicate aliases: ${concat ", " clashing}") {}
    attrsets;

  mkSource = {
    categories,
    description,
    ...
  } @ source:
    assert all (category:
      elem category [
        "ai"
        "archives"
        "audio"
        "communication"
        "core"
        "desktop-cli"
        "desktop-ui"
        "editors"
        "files"
        "formatters"
        "media"
        "networking"
        "scripting"
        "shells"
        "system"
        "terminal"
        "text"
        "version-control"
        "video"
      ])
    categories;
      source // {inherit categories description;};
in
  importMerged ./.
