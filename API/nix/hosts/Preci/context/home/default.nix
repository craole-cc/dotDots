{
  data,
  lix,
  ...
}: let
  inherit (lix.attrsets) listToAttrs attrValues;
  inherit (lix.lists) map unique;

  home = listToAttrs (map (user: {
    inherit (user) name;
    value = {
      packages = unique (
        user.infrastructure.packages.packages
        ++ (user.infrastructure.capabilities.home.packages or [])
      );
    };
  }) (attrValues data.principals));
in
  home
