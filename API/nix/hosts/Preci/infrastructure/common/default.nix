{host, inputs, lix, ...}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) concatMap elem map unique;

  capabilities = import ./capabilities.nix {inherit lix;};
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

  resolveRust = user: let
    rust = user.capabilities.development.languages.rust or null;
    channel = if rust == null then null else rust.channel or "stable";
    extensions = if rust == null then [] else rust.components or [];
  in if rust == null then [] else [
    (if channel == "nightly"
      then inputs.nixpkgs.rust-bin.nightly.latest.default
      else inputs.nixpkgs.rust-bin.stable.latest.default
    ).override {inherit extensions;}
  ];

  principals = listToAttrs (map (declaration: let
    resolvedPackages = resolveUserPackages declaration;
  in {
    name = declaration.name;
    value = declaration // {
      resolution = {
        capabilities = capabilities.resolve {inherit host; user = declaration;};
        packages = resolvedPackages;
      };
      packages = (declaration.packages or {}) // {
        packages = resolvedPackages.packages ++ resolveRust declaration;
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
