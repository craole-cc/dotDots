{host, inputs, lix, ...}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) map;

  capabilities = import ./capabilities.nix {inherit lix;};
  packages = import ./packages.nix {inherit lix;};
  packageResolver = packages // {
    pkgs = inputs.nixpkgs;
  };
  functionalities = import ./functionalities.nix {inherit lix;};
  principal = import ./principal.nix {
    inherit capabilities;
    packages = packageResolver;
  };

  resolved = {
    host = host // {
      resolution = {
        functionalities = functionalities.resolve host.functionalities;
        packages = packages.resolveHost {
          inherit host;
          pkgs = packageResolver.pkgs;
        };
      };
    };

    principals = listToAttrs (map
      (principal: {
        name = principal.name;
        value = principal.resolve {
          inherit host;
          user = principal;
        };
      })
      host.principals.all);
  };
in
  resolved
