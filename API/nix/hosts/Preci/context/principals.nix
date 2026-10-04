{
  lix,
  capabilities,
  host,
  pkgs,
  #? The pools a principal's package names may live in, beyond nixpkgs: the
  #? fetched package sets and flakes, with `pkgs` under its own key. Built by
  #? `packages.nix` and passed through, so principal packages and host packages
  #? resolve against the same set of sources -- one order, one alias table.
  sources ? {},
  ...
}: let
  inherit (lix.attrsets) attrValues listToAttrs;
  inherit (lix.schemas.user.packages) resolvePackages;
  inherit (lix.strings) aliasOf;
in
  listToAttrs (
    map (user: let
      inherit (user) name;
      context = {
        capabilities = capabilities.resolve {inherit user;};
        packages = resolvePackages {
          inherit user pkgs aliasOf;
          #? `sources` is keyed by registry name; the resolver wants them in
          #? search order, which is that key order.
          extra = attrValues sources;
        };
      };
      value = user // {inherit context;};
    in {inherit name value;})
    host.principals.defined
  )
