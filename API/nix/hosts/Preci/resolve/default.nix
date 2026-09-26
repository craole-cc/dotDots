{host, inputs, lix, ...}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) map;

  capabilities = import ./capabilities.nix {inherit lix;};
  packages = import ./packages.nix {inherit lix;};
  packageResolver = packages // {
    pkgs = inputs.nixpkgs;
  };
  functionalities = import ./functionalities.nix {inherit lix;};
  user = import ./user.nix {
    inherit capabilities;
    packages = packageResolver;
  };

  resolvedHost = host // {
    resolution = {
      functionalities = functionalities.resolve host.functionalities;
      packages = packages.resolveHost {
        inherit host;
        pkgs = packageResolver.pkgs;
      };
    };
  };

  resolvedPrincipals = listToAttrs (map
    (userDeclaration: {
      name = userDeclaration.name;
      value = user.resolve {
        inherit host;
        user = userDeclaration;
      };
    })
    host.principals.all);
in {
  host = resolvedHost;
  principals = resolvedPrincipals;
}
