{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrNames recursiveUpdate;
  inherit (lib.lists) concatMap elem filter foldl' reverseList unique;
  inherit (lix.debug) requireThat;

  mkMergedAttrs = {
    declared,
    requested,
  }: {
    inherit declared requested;
    #> Principal order is significant: earlier principals have priority.
    merged =
      foldl'
      recursiveUpdate
      declared
      (reverseList requested);
  };

  mkMergedList = {
    declared,
    requested,
  }: {
    inherit declared requested;
    merged = unique (requested ++ declared);
  };

  deriveApplications = {
    default,
    defined,
  }: let
    args = defined.applications or {};
    names = attrNames args;
    unknown =
      filter
      (name: !(default.applications ? ${name}))
      names;
    context = "deriveApplications";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown application roles: ${toString unknown}";
    }; args;

  deriveFunctionalities = {
    default,
    defined,
  }: let
    args = defined.functionalities or {};
    names = unique args;
    unknown =
      filter
      (name: !(default.functionalities ? ${name}))
      names;
    context = "deriveFunctionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown functionalities: ${toString unknown}";
    }; names;

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

  resolveNames = {
    pkgs,
    groups,
    names,
    context,
  }: let
    expanded = unique (expandNames {inherit groups names;});
  in
    map (
      name:
        if pkgs ? ${name}
        then pkgs.${name}
        else throw "${context}: package '${name}' was not found in nixpkgs"
    )
    expanded;

  resolveUserPackages = {
    user,
    pkgs,
  }: let
    inherit (user.packages) shells common launchers;
    names = unique (common ++ launchers ++ shells);
  in {
    inherit names;
    expanded = unique (expandNames {
      groups = {inherit shells common launchers;};
      inherit names;
    });
    packages = resolveNames {
      inherit pkgs;
      groups = {inherit shells common launchers;};
      inherit names;
      context = "resolve user '${user.name}'";
    };
  };

    resolvePackages = {
    pkgs,
    args,
  }: let
    isForHost = args ? packages.kernel;
    forUsers =
    context = "resolve packages for '${args.name}'";
    groups = attrNames args.packages;
    names = unique (concatLists (attrValues args.packages));
  in
    {common = resolvePackageGroups {inherit context groups names pkgs;};}
    // (
      optionalAttrs isForHost {
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
in {
  inherit
    deriveApplications
    deriveFunctionalities
    mkMergedAttrs
    mkMergedList
    expandName
    resolveNames
    expandNames
    ;
}
