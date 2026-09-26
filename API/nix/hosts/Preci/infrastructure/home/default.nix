{common, lix, ...}: let
  inherit (lix.attrsets) listToAttrs attrValues;
  inherit (lix.lists) map unique;

  home = listToAttrs (map (user: {
    name = user.name;
    value = {
      packages = unique (
        user.resolved.packages.packages
        ++ (user.resolved.capabilities.home.packages or [])
      );
    };
  }) (attrValues common.principals));
in
  home
