{_, ...}: let
  inherit (_.lists.predicates) isList;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) splitString toPascal;
  inherit (_.attrsets.access) attrByPath;
in {
  # "a.b.c" → ["a" "b" "c"];  lists pass through unchanged
  toPath = field:
    if isList field
    then field
    else splitString "." field;

  # Safe deep-get: returns `default` when any path segment is absent
  toValue = {
    field,
    default ? null,
  }: app:
    attrByPath (
      if isList field
      then field
      else splitString "." field
    )
    default
    app;

  # ["a" "b"] → "byAB"  (optional prefix + PascalCase join, optional suffix)
  toName = {
    prefix ? "",
    field,
    suffix ? "",
  }: let
    normalized = concatStringsSep "-" (
      if isList field
      then field
      else splitString "." field
    );
  in
    prefix + toPascal normalized + suffix;
}
