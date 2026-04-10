{_, ...}: let
  __doc = ''
    Layer 6 — grouped set builders and the mkSection entry point.
    mkStandardGrouped dispatches fields to the right group producer.
    mkSection is the main entry point consumed by sections/*.nix.
    Depends on: primitives, builders, semantic
  '';
  inherit (_.attrsets.construction) genAttrs listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.access) attrValues;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.applications.primitives) toValue toName;
  inherit (_.applications.builders) mkEqQueries mkMemberQueries;
  inherit
    (_.applications.semantic)
    mkMaturityGroup
    mkProtocolGroup
    mkScopeGroup
    mkCapabilityGroup
    mkStandardQueries
    ;

  mkConfigFileGroup = {set}: let
    getVal = toValue {field = "config.file";};
    withCfg = filterAttrs (_: a: toValue {field = "config";} a != null) set;
    keys = unique (filter (v: v != null) (map getVal (attrValues withCfg)));
  in
    genAttrs keys (file: filterAttrs (_: a: getVal a == file) set);

  # Dispatches each field name to the appropriate group producer.
  # Special-cased fields get their semantic producer; all others fall back to
  # mkEqQueries (for `eq` fields) or mkMemberQueries (for `member` fields).
  mkStandardGrouped = {
    set,
    eq ? [],
    member ? [],
    fields ? [],
  }: let
    perField = {
      maturity = mkMaturityGroup {inherit set;};
      protocol = mkProtocolGroup {inherit set;};
      config = mkConfigFileGroup {inherit set;};
      capability = mkCapabilityGroup {inherit set;};
      scope = mkScopeGroup {inherit set;};
    };
    allFields = unique (eq ++ member ++ fields);
  in
    listToAttrs (map (field: {
        name = toName {inherit field;};
        value =
          perField.${
            field
          } or (
            if isIn field eq
            then mkEqQueries {inherit set field;}
            else mkMemberQueries {inherit set field;}
          );
      })
      allFields);
in {
  inherit mkConfigFileGroup mkStandardGrouped;

  # Collapses the repeated section skeleton:
  #
  #   let groups = mkStandardGrouped {…};
  #   in  { all = set; inherit groups; queries = mkStandardQueries {…} // extras; }
  #
  # `extraQueries` is a function `groups -> attrset` so callers can promote
  # group keys into queries without a separate binding:
  #
  #   extraQueries = groups: { inherit (groups.byKind) history fuzzy; }
  mkSection = {
    set,
    grouped ? {},
    queryField ? null,
    extraQueries ? (_: {}),
  }: let
    groups = mkStandardGrouped ({inherit set;} // grouped);
  in {
    all = set;
    inherit groups;
    queries =
      mkStandardQueries {
        inherit set;
        field = queryField;
      }
      // extraQueries groups;
  };
}
