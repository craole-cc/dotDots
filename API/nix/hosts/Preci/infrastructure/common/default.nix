{
  host ? lix.host or {},
  inputs ? lix.inputs or {},
  lix,
  lib,
  ...
}: let
  inherit (lib.attrsets) listToAttrs;
  inherit (lib.lists) concatMap elem map unique;

  capabilities = import ./capabilities.nix {inherit lix inputs;};
  functionalities = import ./functionalities.nix {inherit lix host;};

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

  resolveUserPackages = user: let
    inherit (user.packages) shells common launchers;
    names = unique (common ++ launchers ++ shells);
  in {
    inherit names;
    expanded = unique (expandNames {
      groups = {inherit shells common launchers;};
      inherit names;
    });
    packages = resolveNames {
      pkgs = inputs.nixpkgs;
      groups = {inherit shells common launchers;};
      inherit names;
      context = "resolve user '${user.name}'";
    };
  };

  principals = listToAttrs (map (declaration: let
      resolvedCapabilities = capabilities.resolve {user = declaration;};
      resolvedPackages = resolveUserPackages declaration;
    in {
      name = declaration.name;
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

  packages = let
    inherit (host.packages) shells coding common launchers;
    names = unique (common ++ coding ++ launchers ++ shells);
  in {
    kernel = let
      name = host.packages.kernel;
    in {
      inherit name;
      package =
        if inputs ? nixpkgs.${name}
        then inputs.nixpkgs.${name}
        else
          throw "resolve host '${
            host.name
          }': kernel package '${name}' was not found in nixpkgs";
    };

    common = resolveNames {
      pkgs = inputs.nixpkgs;
      groups = {inherit shells coding common launchers;};
      inherit names;
      context = "resolve host '${host.name}'";
    };
  };
in {
  inherit packages principals;
  functionalities = functionalities.resolved;
}
