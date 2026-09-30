{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues optionalAttrs;
  inherit (lib.lists) concatLists concatMap elem unique;
  inherit (lix.trivial) isNotEmpty;

  resolvePackage = pkgs: name:
    pkgs.${name} or null;

  expandName = groups: stack: name:
    if elem name stack
    then throw "resolve packages: cyclic package group '${name}'"
    else if groups ? ${name}
    then
      concatMap
      (expandName groups (stack ++ [name]))
      groups.${name}
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
  # resolvePackages = {
  #   pkgs,
  #   args,
  # }: let
  #   isForHost = args ? packages.kernel;
  #   forUsers =
  #   context = "resolve packages for '${args.name}'";
  #   groups = attrNames args.packages;
  #   names = unique (concatLists (attrValues args.packages));
  # in
  #   {common = resolvePackageGroups {inherit context groups names pkgs;};}
  #   // (
  #     optionalAttrs isForHost {
  #       kernel = let
  #         name = args.packages.kernel;
  #         pkg = resolvePackage pkgs name;
  #       in {
  #         inherit name;
  #         package =
  #           if isNotEmpty pkg
  #           then pkg
  #           else
  #             throw "resolve host '${
  #               args.name
  #             }': kernel package '${name}' was not found in nixpkgs";
  #       };
  #     }
  #   );
in {inherit resolvePackage;}
