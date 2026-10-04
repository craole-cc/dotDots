{
  lib ? import <nixpkgs/lib>,
  lix,
  host,
  inputs ? lix.inputs or {},
  ...
}: let
  inherit (lib.attrsets) attrValues listToAttrs removeAttrs;
  inherit (lib.lists) concatLists map unique;

  #? One implementation of group expansion, shared by the user and host
  #? resolvers. `data/lib.nix` is the single home for this logic; keeping a
  #? second copy here is how the two drifted apart in the first place.
  inherit (import ./lib.nix {inherit lib;}) expandNames resolveNames;
  inherit (lix.packages) resolvePackageGroups;

  capabilities = import ./capabilities.nix {inherit lix lib inputs;};
  functionalities = import ./functionalities.nix {inherit lix host;};

  #? `lix.inputs` entries are *source records* (owner/rev/path/...), not
  #? package sets. Reading `inputs.nixpkgs.<pkg>` looks the attribute up on that
  #? record, which has no packages on it, so every resolution silently misses.
  #? The package set comes from importing the pinned source at `.path`.
  pkgs =
    inputs.nixpkgs.pkgs
    or (import inputs.nixpkgs.path {inherit (host) system;});

  #? The group vocabulary is the user's own declared package groups, read from
  #? `user.packages` rather than hardcoded: the schema declares `shell`,
  #? `common` and `launcher` (singular), and a resolver that assumes
  #? `shells`/`launchers` throws on every real principal. Group names are also
  #? self-referential -- a group's value list may name another group -- so the
  #? expansion below walks the declared groups rather than a fixed set.
  resolveUserPackages = user: let
    declared = user.packages or {};
    groups = removeAttrs declared ["encoding" "meta"];
    names = unique (concatLists (attrValues groups));
    expanded = unique (expandNames {inherit groups names;});
  in {
    inherit names expanded groups;
    packages = resolvePackageGroups {
      inherit pkgs;
      inherit groups names;
      context = "resolve user '${user.name}'";
    };
  };

  principals = listToAttrs (map (declaration: let
      resolvedCapabilities = capabilities.resolve {user = declaration;};
      resolvedPackages = resolveUserPackages declaration;
    in {
      inherit (declaration) name;
      value =
        declaration
        // {
          infrastructure = {
            capabilities = resolvedCapabilities;
            packages = resolvedPackages;
          };
        };
    })
    host.principals.all);

  #? Host packages follow the same rule as user packages: the declared groups are
  #? the vocabulary, and `kernel` is a name to resolve rather than a group.
  packages = let
    groups = removeAttrs (host.packages or {}) ["kernel"];
    names = unique (concatLists (attrValues groups));
  in {
    kernel = let
      name = host.packages.kernel;
    in {
      inherit name;
      package =
        pkgs.${name}
        or (throw "resolve host '${host.name}': kernel package '${name}' was not found in nixpkgs");
    };

    common = resolveNames {
      inherit pkgs;
      inherit groups names;
      context = "resolve host '${host.name}'";
    };
  };
in {
  inherit packages principals;
  functionalities = functionalities.resolved;
}
