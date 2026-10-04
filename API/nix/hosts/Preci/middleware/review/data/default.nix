{
  lix,
  host,
  inputs ? lix.inputs or {},
  ...
}: let
  inherit (lix.attrsets) attrValues listToAttrs;
  inherit (lix.lists) concatLists unique;
  inherit (lix.schemas.user) resolvePackages;
  inherit (lix.packages) resolvePackageGroups;

  capabilities = import ./capabilities.nix {inherit lix inputs;};
  functionalities = import ./functionalities.nix {inherit lix host;};
  interface = import ./interface.nix {inherit lix host;};
  principals = import ./principals.nix {inherit lix host;};

  #? `lix.inputs` entries are *source records* (owner/rev/path/...), not
  #? package sets. Reading `inputs.nixpkgs.<pkg>` looks the attribute up on that
  #? record, which has no packages on it, so every resolution silently misses.
  #? The package set comes from importing the pinned source at `.path`.
  # TODO: Should this be using mkNixPkgs? Is it not here that we would add overlays? (Maybe bnnot, maybe later, but what if we want cachyOS kernes, that comes from an overlay (not yet defined, but still))
  pkgs =
    inputs.nixpkgs.pkgs
    or (import inputs.nixpkgs.path {inherit (host) system;});

  # TODO: Whay do we do this exaxt same thing twice (her and in principals.nix)
  principals = listToAttrs (
    map (user: let
      inherit (user) name;
      context = {
        capabilities = capabilities.resolve {inherit user;};
        packages = resolvePackages user;
      };
      value = user // {inherit context;};
    in {inherit name value;})
    host.principals.defined
  );

  #? Host packages follow the same rule as user packages: the declared groups are
  #? the vocabulary, and `kernel` is a name to resolve rather than a group.
  packages = let
    groups = removeAttrs (host.packages or {}) ["kernel"];
    names = unique (concatLists (attrValues groups));
  in {
    kernel = let
      name = host.packages.kernel;
      err = "resolve host '${
        host.name
      }': kernel package '${name}' was not found in nixpkgs";
      package = pkgs.${name} or (throw err);
    in {inherit name package;};

    common = resolvePackageGroups {
      inherit pkgs;
      inherit groups names;
      context = "resolve host '${host.name}'";
    };
  };
in {
  inherit packages principals;
  #? The imbued interface view: what the principals asked for, what the host
  #? declares, what they can have together, and which one is the session. This
  #? is the reconciliation the two declaration trees could not do on their own.
  inherit interface;
  functionalities = functionalities.resolved;
}
