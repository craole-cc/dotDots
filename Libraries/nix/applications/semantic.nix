# helpers/semantic.nix
# Layer 5 — domain-aware semantic helpers.
# Knows application field names (maturity, protocol, scope, etc.) and produces
# consistently-named group buckets and query predicates from them.
# Depends on: primitives, predicates, builders, selectors
{
  _,
  primitives,
  predicates,
  builders,
  selectors,
}: let
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs optionalAttrs;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (primitives) toValue;
  inherit (predicates) hasField;
  inherit (builders) mkEqQueries mkMemberQueries mkBoolQueries mkLengthQueriesFor mkNamedQueries;
  inherit (selectors) withFlag withoutFlag;

  # ── Group producers (keyed buckets) ─────────────────────────────────────────
  mkMaturityGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "maturity";
    };
  mkProtocolGroup = {set}:
    mkMemberQueries {
      inherit set;
      field = "protocol";
    };
  mkScopeGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "scope";
    };
  mkCapabilityGroup = {set}: let
    fields = ["acceleration" "compositing" "remote" "floating"];
  in
    filterAttrs (_: v: v != {}) (genAttrs fields (field: withFlag {inherit field set;}));

  # ── Query producers (named predicates) ──────────────────────────────────────
  mkMaturityQueries = {set}:
    mkNamedQueries {
      prefix = "is";
      set = mkMaturityGroup {inherit set;};
    };
  mkProtocolQueries = {set}:
    mkNamedQueries {
      prefix = "for";
      set = mkProtocolGroup {inherit set;};
    };
  mkScopeQueries = {set}:
    mkNamedQueries {
      prefix = "as";
      set = mkScopeGroup {inherit set;};
    };
  mkCapabilityQueries = {set}:
    mkNamedQueries {
      prefix = "has";
      set = mkCapabilityGroup {inherit set;};
    };

  # present only when field exists in set; produces { independent = …; integrated = …; }
  mkIndependenceQueries = {set}: let
    field = "independent";
  in
    optionalAttrs (hasField {inherit field set;})
    (mkBoolQueries {
      inherit field set;
      trueKey = field;
      falseKey = "integrated";
    });

  # present only when any app has a config attrset with a `file` key
  mkConfigQueries = {set}: let
    withConfig = filterAttrs (_: a: let cfg = toValue {field = "config";} a; in isAttrs cfg && cfg ? file) set;
    profileOnly = filterAttrs (_: a: toValue {field = "config.file";} a == ".profile") withConfig;
    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
  in
    optionalAttrs (withConfig != {}) {inherit isConfigurable;};
in {
  inherit
    mkMaturityGroup
    mkProtocolGroup
    mkScopeGroup
    mkCapabilityGroup
    mkMaturityQueries
    mkProtocolQueries
    mkScopeQueries
    mkCapabilityQueries
    mkIndependenceQueries
    mkConfigQueries
    ;

  # Applies every semantic query family; each is a no-op when its field is absent
  mkStandardQueries = {
    set,
    field ? null,
  }:
    mkCapabilityQueries {inherit set;}
    // mkConfigQueries {inherit set;}
    // mkIndependenceQueries {inherit set;}
    // mkMaturityQueries {inherit set;}
    // mkProtocolQueries {inherit set;}
    // mkScopeQueries {inherit set;}
    // mkLengthQueriesFor {inherit set field;};
}
