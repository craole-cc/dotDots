{_, ...}: let
  inherit (_.attrsets.aggregation) recursiveUpdateUntil;
  inherit (_.attrsets.predicates) isDerivation;
  inherit (_.types.predicates) isAttrs isFunction;

  # Empty attrsets are explicit selections; nonempty records merge by key.
  merge = base: override:
    if override == {}
    then base
    else
      recursiveUpdateUntil (_path: previous: value:
        !isAttrs previous || !isAttrs value || isDerivation value || value == {})
      base
      override;

  mkHermes = {
    defaults ? {},
    host ? {},
    user ? {},
    lix,
    homeDirectory,
  }: let
    materialize = value:
      if isFunction value
      then value {inherit lix homeDirectory;}
      else value;
    hostSettings = materialize (host.ai.hermes or (host.defaults.ai.hermes or {}));
    userSettings = materialize (user.ai.hermes or {});
  in
    merge (merge defaults hostSettings) userSettings;
in {inherit mkHermes;}
