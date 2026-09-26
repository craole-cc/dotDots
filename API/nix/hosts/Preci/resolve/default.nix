{host, inputs, lix, ...}: let
  capabilities = import ./capabilities.nix {inherit lix;};
  packages = import ./packages.nix {inherit lix;};
  packageResolver = packages // {
    pkgs = inputs.nixpkgs;
  };
  hostResolver = import ./host.nix {inherit lix;};
  principalResolver = import ./principal.nix {
    inherit capabilities;
    packages = packageResolver;
  };

  resolvedHost = hostResolver.resolve {
    inherit host;
    packages = packageResolver;
  };

  resolvedPrincipals =
    lix.attrsets.listToAttrs
    (lix.lists.map
      (
        user: {
          name = user.name;
          value = principalResolver.resolve {
            inherit host user;
          };
        }
      )
      host.principals.all);
in {
  host = resolvedHost;
  principals = resolvedPrincipals;
}
