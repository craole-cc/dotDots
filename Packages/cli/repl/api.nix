{
  lib,
  api,
  host,
  users,
}: let
  inherit (lib.attrsets) attrByPath attrNames;
  inherit (lib.lists) length head filter;
  inherit (lib.strings) splitString;

  currentUser = head (attrNames users);
  hostApi = api.hosts.${host.name} or null;
  userApi = api.users.${currentUser} or null;

  # Helper to find all nested keys
  allKeys = set: lib.lists.unique (lib.attrsets.collect (x: builtins.isAttrs x) set);

  # Flatten nested structures for comparison
  flattenAttrs = prefix: set:
    lib.attrsets.mapAttrs' (
      name: value:
        if builtins.isAttrs value && !(value ? outPath) && !(value ? type)
        then flattenAttrs (prefix + "${name}.") value
        else {
          name = prefix + name;
          value = value;
        }
    )
    set;

  flatHost =
    if hostApi != null
    then flattenAttrs "" hostApi
    else {};
  flatUser =
    if userApi != null
    then flattenAttrs "" userApi
    else {};

  # Find differences
  hostKeys = attrNames flatHost;
  userKeys = attrNames flatUser;
  allUniqueKeys = lib.lists.unique (hostKeys ++ userKeys);

  # Compare each key
  differences = lib.attrsets.genAttrs allUniqueKeys (key: {
    host = flatHost.${key} or null;
    user = flatUser.${key} or null;
    equal = (flatHost.${key} or null) == (flatUser.${key} or null);
  });

  apiComparison = let
    inherit hostApi userApi;

    overlappingKeys = filter (k: hostApi ? ${k} && userApi ? ${k}) (attrNames hostApi);
    hostOnlyKeys = filter (k: hostApi ? ${k} && !(userApi ? ${k})) (attrNames hostApi);
    userOnlyKeys = filter (k: userApi ? ${k} && !(hostApi ? ${k})) (attrNames userApi);

    interface = {
      host = hostApi.interface or null;
      user = userApi.interface or null;
      equal = (hostApi.interface or null) == (userApi.interface or null);
    };

    paths = {
      host = hostApi.paths or null;
      user = userApi.paths or null;
      equal = (hostApi.paths or null) == (userApi.paths or null);
    };

    allDifferences = lib.attrsets.filterAttrs (key: value: !value.equal) differences;

    summary = {
      totalHostKeys = length (attrNames hostApi);
      totalUserKeys = length (attrNames userApi);
      overlapping = length overlappingKeys;
      hostOnly = length hostOnlyKeys;
      userOnly = length userOnlyKeys;
    };
  in {
    inherit interface paths allDifferences summary;
  };

  compareApiAttribute = attr: {
    host = attrByPath (splitString "." attr) null hostApi;
    user = attrByPath (splitString "." attr) null userApi;
    equal =
      (attrByPath (splitString "." attr) null hostApi)
      == (attrByPath (splitString "." attr) null userApi);
  };
in {
  api = {
    host = hostApi;
    user = userApi;
    comparison = apiComparison;
    inherit compareApiAttribute;
  };
}
