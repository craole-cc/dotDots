{host, inputs, lix, ...}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) concatMap elem map unique;

  capabilities = import ./capabilities.nix {inherit inputs lix;};
  functionalities = import ./functionalities.nix {inherit lix;};

  expandName = groups: stack: name:
    if elem name stack
    then throw "resolve packages: cyclic package group '${name}'"
    else if groups ? ${name}
    then concatMap (expandName groups (stack ++ [name])) groups.${name}
    else [name];

  expandNames = {groups, names}: concatMap (expandName groups []) names;

  resolveNames = {pkgs, groups, names, context}: let
    expanded = unique (expandNames {inherit groups names;});
  in map (name:
    if pkgs ? ${name}
    then pkgs.${name}
    else throw "${context}: package '${name}' was not found in nixpkgs"
  ) expanded;

  resolveUserPackages = user: let
    inherit (user.packages) shells common launchers;
    names = unique (common ++ launchers ++ shells);
  in {
    inherit names;
    expanded = unique (expandNames {groups = {inherit shells common launchers;}; inherit names;});
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
    value = declaration // {
      infrastructure = {
        capabilities = resolvedCapabilities;
        packages = resolvedPackages;
      };
    };
  }) host.principals.all);

  hostPackages = let
    inherit (host.packages) shells coding common launchers;
    names = unique (common ++ coding ++ launchers ++ shells);
  in {
    kernel = {
      name = host.packages.kernel;
      package =
        if inputs.nixpkgs ? ${host.packages.kernel}
        then inputs.nixpkgs.${host.packages.kernel}
        else throw "resolve host '${host.name}': kernel package '${host.packages.kernel}' was not found in nixpkgs";
    };
    common = resolveNames {
      pkgs = inputs.nixpkgs;
      groups = {inherit shells coding common launchers;};
      inherit names;
      context = "resolve host '${host.name}'";
    };
  };
in {
  inherit principals;
  functionalities = functionalities.resolve host.functionalities;
  packages = hostPackages;
}
