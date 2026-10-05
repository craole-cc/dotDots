{
  lix,
  capabilities,
  host,
  pkgs ? pools.nixpkgs or null,
  #? The pools a principal's package names may live in, beyond nixpkgs: the
  #? fetched package sets and flakes, with `pkgs` under its own key. Built by
  #? `packages.nix` and passed through, so principal packages and host packages
  #? resolve against the same set of sources -- one order, one alias table.
  pools,
  ...
}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.types.user.packages) resolvePackages;
in
  listToAttrs (
    map (user: let
      inherit (user) name;
      context = {
        capabilities = capabilities.resolve {inherit user;};
        packages = resolvePackages {inherit user pkgs pools;};
      };
      value = user // {inherit context;};
    in {inherit name value;})
    host.principals.defined
  )
