{
  lix,
  capabilities,
  host,
  pkgs,
  ...
}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.schemas.user.packages) resolvePackages;
in
  listToAttrs (
    map (user: let
      inherit (user) name;
      context = {
        capabilities = capabilities.resolve {inherit user;};
        packages = resolvePackages {inherit user pkgs;};
      };
      value = user // {inherit context;};
    in {inherit name value;})
    host.principals.defined
  )
