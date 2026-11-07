{_, ...}: let
  __exports = {
    internal = {inherit mkHermes profileNames isValidProfileName;};
    external = {};
  };

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
      recursiveUpdateUntil (
        _path: previous: value:
          !isAttrs previous || !isAttrs value || isDerivation value || value == {}
      )
      base
      override;

  /**
  Normalises Hermes settings from defaults, host and user selections.

  Function-valued selections receive the library, Home Manager home directory
  and effective Hermes home path before merging. User settings take precedence over host settings and defaults.
  */
  mkHermes = {
    defaults ? {},
    host ? {},
    user ? {},
    lix,
    homeDirectory,
    homePath ? null,
  }: let
    materialise = value:
      if isFunction value
      then value {inherit lix homeDirectory homePath;}
      else value;
    hostSettings = materialise (host.ai.hermes or (host.defaults.ai.hermes or {}));
    userSettings = materialise (user.ai.hermes or {});
  in
    merge (merge defaults hostSettings) userSettings;
in
  __exports.internal
  // {__rootAliases = __exports.external;}
