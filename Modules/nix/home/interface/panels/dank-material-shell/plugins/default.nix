{lix, ...} @ args: let
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.transformation) unique;

  categories = import ./types args;
  plugins =
    foldl'
    (plugins: category: plugins // category.plugins) {}
    categories;
  packages =
    unique
    (concatMap (category: category.packages or []) categories);
in
  (import ./migration.nix args)
  // (import ./activation.nix args)
  // {inherit plugins packages categories;}
