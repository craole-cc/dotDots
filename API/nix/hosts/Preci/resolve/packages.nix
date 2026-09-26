{lix, ...}: let
  resolveNames = {
    pkgs,
    names,
    context,
  }:
    lix.lists.map
    (
      name:
        if pkgs ? ${name}
        then pkgs.${name}
        else throw "${context}: package '${name}' was not found in nixpkgs"
    )
    (lix.lists.unique names);

  resolveUser = {
    pkgs,
    user,
  }: let
    names = lix.lists.unique (
      user.packages.common
      ++ user.packages.coding
      ++ user.packages.launchers
      ++ user.packages.shells
    );
  in {
    inherit names;
    packages = resolveNames {
      inherit pkgs names;
      context = "resolve principal '${user.name}'";
    };
  };
in {
  resolveHost = {
    host,
    pkgs,
  }: {
    kernel = {
      name = host.packages.kernel;
      package =
        if pkgs ? ${host.packages.kernel}
        then pkgs.${host.packages.kernel}
        else throw "resolve host '${host.name}': kernel package '${host.packages.kernel}' was not found in nixpkgs";
    };

    common = resolveNames {
      inherit pkgs;
      names =
        host.packages.common
        ++ host.packages.coding
        ++ host.packages.launchers
        ++ host.packages.shells;
      context = "resolve host '${host.name}'";
    };
  };

  inherit resolveUser;
}
