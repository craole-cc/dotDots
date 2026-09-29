{common, lix, ...}: let
  inherit (lix.attrsets) listToAttrs attrValues;
  inherit (lix.lists) map unique;

  home = listToAttrs (map (user: {
    name = user.name;
    value = {
      packages = unique (
        user.infrastructure.packages.packages
        ++ (user.infrastructure.capabilities.home.packages or [])
      );
    };
  }) (attrValues common.principals));
in
  home
