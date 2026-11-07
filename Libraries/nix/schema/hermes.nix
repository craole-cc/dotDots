{_, ...}: let
  inherit (_.attrsets.aggregation) recursiveUpdateUntil;
  inherit (_.attrsets.predicates) isDerivation;
  inherit (_.types.predicates) isAttrs isFunction;
  inherit (_.strings.access) match;
  inherit (_.lists.predicates) elem;

  profileNames = {
    pattern = "[a-z0-9][a-z0-9_-]{0,63}";
    reserved = ["default"];
  };
  isValidProfileName = name:
    !(elem name profileNames.reserved) && match profileNames.pattern name != null;

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
in {inherit mkHermes profileNames isValidProfileName;}
