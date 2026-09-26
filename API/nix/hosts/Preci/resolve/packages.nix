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
    inherit (user.packages) shells common launchers;
    names = unique (common ++ launchers ++ shells);
    expanded = unique (expandNames {
      groups = {
        inherit shells common launchers;
      };
      inherit names;
    });
  in {
    inherit names expanded;
    packages = resolveNames {
      inherit pkgs names;
      groups = {
        inherit shells common launchers;
      };
      context = "resolve user '${user.name}'";
    };
  };
in {
  resolveHost = {
    host,
    pkgs,
  }: let
    inherit (host.packages) shells coding common launchers;
    names = unique (common ++ coding ++ launchers ++ shells);
    expanded = unique (expandNames {
      groups = {
        inherit shells coding common launchers;
      };
      inherit names;
    });
  in {
    kernel = {
      name = host.packages.kernel;
      package =
        if pkgs ? ${host.packages.kernel}
        then pkgs.${host.packages.kernel}
        else throw "resolve host '${host.name}': kernel package '${host.packages.kernel}' was not found in nixpkgs";
    };

    common = resolveNames {
      inherit pkgs names;
      groups = {
        inherit shells coding common launchers;
      };
      context = "resolve host '${host.name}'";
    };
  };

  inherit resolveUser;
}
