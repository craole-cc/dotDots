{
  lix,
  resolveNames,
  lib,
  ...
}: let
  inherit (lix.attrsets) attrNames attrValues optionalAttrs;
  inherit (lib.lists) concatLists concatMap elem unique;
  inherit (lix.packages) resolvePackage resolvePackageG;
  inherit (lix.trivial) isNotEmpty;

  # resolveUserPackages = pkgs: user: let
  #   context = "resolve user '${user.name}'";
  #   groups = {inherit (user.packages) shells common launchers;};
  #   names = unique (concatLists (attrValues groups));
  # in {
  #   expanded = unique (expandNames {inherit groups names;});
  #   packages = resolveNames {inherit context pkgs groups names;};
  # };

  # resolveHostPackages = pkgs: host: let
  #   context = "resolve host '${host.name}'";
  #   groups = {inherit (user.packages) shells common launchers;};
  #   names = unique (concatLists (attrValues groups));
  # in {
  #   expanded = unique (expandNames {inherit groups names;});
  #   packages = resolveNames {inherit context pkgs groups names;};
  # };

  expandName = groups: stack: name:
    if elem name stack
    then throw "resolve packages: cyclic package group '${name}'"
    else if groups ? ${name}
    then concatMap (expandName groups (stack ++ [name])) groups.${name}
    else [name];

  expandNames = {
    groups,
    names,
  }:
    concatMap (expandName groups []) names;

  resolvePackageGroups = {
    pkgs,
    groups,
    names,
    context,
  }: let
    expanded = unique (expandNames {inherit groups names;});
  in
    map (
      name:
        pkgs.${name} or (throw "${context}: package '${name}' was not found in nixpkgs")
    )
    expanded;

  resolvePackages = {
    pkgs,
    args,
  }: let
    context = "resolve packages for '${args.name}'";
    groups = attrNames args.packages;
    names = unique (concatLists (attrValues args.packages));
  in
    {common = resolveNames {inherit context groups names pkgs;};}
    // (
      optionalAttrs (args ? packages.kernel) {
        kernel = let
          name = args.packages.kernel;
          pkg = resolvePackage pkgs name;
        in {
          inherit name;
          package =
            if isNotEmpty pkg
            then pkg
            else
              throw "resolve host '${
                args.name
              }': kernel package '${name}' was not found in nixpkgs";
        };
      }
    );
in {inherit resolvePackages resolvePackageGroups;}
