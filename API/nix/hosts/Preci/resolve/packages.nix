{lix, ...}: let
  inherit (lix.lists) concatMap elem map unique;

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
    map
    (
      name:
        if pkgs ? ${name}
        then pkgs.${name}
        else throw "${context}: package '${name}' was not found in nixpkgs"
    )
    expanded;

  resolveUser = {
    pkgs,
    user,
  }: let
    groups = {
      shells = user.packages.shells;
      coding = user.packages.coding;
      common = user.packages.common;
      launchers = user.packages.launchers;
    };
    names = unique (
      user.packages.common
      ++ user.packages.coding
      ++ user.packages.launchers
      ++ user.packages.shells
    );
    expanded = unique (expandNames {inherit groups names;});
  in {
    inherit names expanded;
    packages = resolveNames {
      inherit pkgs groups;
      names = expanded;
      context = "resolve principal '${user.name}'";
    };
  };
in {
  resolveHost = {
    host,
    pkgs,
  }: let
    groups = {
      shells = host.packages.shells;
      coding = host.packages.coding;
      common = host.packages.common;
      launchers = host.packages.launchers;
    };
    names = unique (
      host.packages.common
      ++ host.packages.coding
      ++ host.packages.launchers
      ++ host.packages.shells
    );
    expanded = unique (expandNames {inherit groups names;});
  in {
    kernel = {
      name = host.packages.kernel;
      package =
        if pkgs ? ${host.packages.kernel}
        then pkgs.${host.packages.kernel}
        else throw "resolve host '${host.name}': kernel package '${host.packages.kernel}' was not found in nixpkgs";
    };

    common = resolveNames {
      inherit pkgs groups;
      names = expanded;
      context = "resolve host '${host.name}'";
    };
  };

  inherit resolveUser;
}
