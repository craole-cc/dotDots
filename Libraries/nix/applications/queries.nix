{_, ...}: let
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.reduction) concatMap;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.transformation) toPascal;
  inherit (_.applications.primitives) toValue toName;
  inherit (_.applications.predicates) hasListField;
  inherit (_.applications.selectors) withFlag withoutFlag;

  # Internal: used by both mkLengthQueries and mkLengthQueriesFor
  mkLengthQueries' = {
    field,
    singleKey,
    multiKey,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
  in {
    ${singleKey} = filterAttrs (_: a: length (getVal a) == 1) set;
    ${multiKey} = filterAttrs (_: a: length (getVal a) > 1) set;
  };
in {
  # { stable = <set>, young = <set>, … }  — one bucket per distinct field value
  mkEqQueries = {
    field,
    set,
  }: let
    getVal = toValue {inherit field;};
    keys = unique (filter (v: v != null) (map getVal (attrValues set)));
  in
    genAttrs keys (value: filterAttrs (_: a: getVal a == value) set);

  # { bash = <set>, zsh = <set>, … }  — one bucket per distinct list member
  mkMemberQueries = {
    field,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
    keys = unique (concatMap getVal (attrValues set));
  in
    genAttrs keys (value: filterAttrs (_: a: isIn value (getVal a)) set);

  # { <trueKey> = flagged set;  <falseKey> = unflagged set }
  mkBoolQueries = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };

  # { <singleKey> = apps with exactly 1 member;  <multiKey> = apps with 2+ }
  mkLengthQueries = mkLengthQueries';

  # Conditional mkLengthQueries: no-op when field is null or has no list values in set
  mkLengthQueriesFor = {
    set,
    field,
  }:
    optionalAttrs (field != null)
    (optionalAttrs (hasListField {inherit field set;})
      (mkLengthQueries' {
        inherit set field;
        singleKey = "single" + toPascal field;
        multiKey = "multi" + toPascal field;
      }));

  # Renames attrset keys by applying a prefix/suffix through toName.
  # { stable = …; young = …; } → { isStable = …; isYoung = …; }
  mkNamedQueries = {
    prefix,
    set,
    suffix ? "",
  }:
    listToAttrs (map (field: {
      name = toName {inherit prefix suffix field;};
      value = set.${field};
    }) (attrNames set));
}
