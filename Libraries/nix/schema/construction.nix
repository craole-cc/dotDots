{
  _,
  _defaults,
  ...
}: let
  __exports = {
    internal = {
      inherit mkSchema;
      inherit (_.schema.applications) mkApplications;
      inherit (_.schema.hardware) mkHardware;
      inherit (_.schema.home) mkHome;
      inherit (_.schema.io) mkKeyboard mkHyprKeybinds;
      inherit (_.schema.locale) mkLocale;
      inherit (_.schema.settings) mkSettings;
      inherit (_.schema.ui) mkUI;
    };
    external = {inherit mkSchema;};
  };

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.predicates) isPathLike pathExists;
  inherit (_.filesystem.resolution) pathAttrs;
  inherit (_.filesystem.traversal) foldersToExclude readDir;
  inherit (_.schema.core) mkCore;
  inherit (_.schema.home) mkUsers;
  inherit (_.schema.settings) mkSettings;
  inherit (_.types.predicates) isAttrs;

  /**
  Import one identity domain (`hosts`, `users`) child directory at a time.

  This mirrors `filesystem.importAttrs` - each immediate subdirectory is
  imported and keyed by its on-disk name, with the domain `default.nix`
  recursively merged underneath - but decides per child whether it qualifies,
  instead of importing the whole domain and discovering the problem afterwards.

  A host still on the self-contained host-system contract has a `default.nix`
  that is a function rather than a data attrset. `importAttrs` cannot skip it:
  `recursiveUpdate` against a lambda throws while the domain attrset is being
  built, so the whole schema fails before any caller can filter the result.
  Qualifying each child first keeps such a host out of the schema entirely -
  it is simply not a schema host yet - while every host that does declare a
  data attrset keeps the normal merge semantics.

  # Type
  ```nix
  importIdentities :: path -> AttrSet
  ```
  */
  importIdentities = dir: let
    entries = readDir dir;

    domainDefault =
      if entries ? "default.nix"
      then import (dir + "/default.nix")
      else {};

    childNames =
      builtins.filter (
        name:
          entries.${name} == "directory" && !(builtins.elem name foldersToExclude)
      )
      (attrNames entries);

    isIdentity = name: let
      default = dir + "/${name}/default.nix";
    in
    pathExists default && isAttrs (import default);
  in
  listToAttrs (
    map (
      name: {
        inherit name;
        value =
          if isIdentity name
          then recursiveUpdate domainDefault (import (dir + "/${name}"))
          else domainDefault;
      }
    ) childNames
  );

  /**
  Enrich each declared host and user from the API.

  Host and user identity records are atomic at their named `default.nix`.
  Nested directories below a host/user belong to that identity but must not
  replace its profile data. Other API domains may remain recursively shaped.
  No active host is inferred here.
  */
  mkSchema = {api ? _defaults.paths.repo.api.default.store, ...}: let
    api' = pathAttrs api;

    identities = name: fallback:
      if isPathLike api
      then importIdentities (api + "/${name}")
      else fallback;

    raw =
      api'
      // {
        global = api'.global or {};
        paths = api'.paths or (api'.global.paths or {});
        shells = api'.shells or {};
        users = identities "users" (api'.users or {});
        hosts = identities "hosts" (api'.hosts or {});
      };

    inherit (raw) paths;
    users = mkUsers {inherit (raw) users;};
    hosts =
      mapAttrs (
        name: host:
          mkCore (
            {
              settings = mkSettings {
                inherit (raw) global;
                inherit host;
              };
              inherit users host name;
              inherit (raw) shells;
            }
            // paths
          )
      )
      raw.hosts;
  in
  raw
  // {
    inherit hosts users;
  };
in
  __exports.internal // {__rootAliases = __exports.external;}