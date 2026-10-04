{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  inherit (lix.attrsets) attrValues;
  inherit (lix.lists) concatLists unique;
  inherit (lix.packages) resolvePackageGroups;

  default = {
    kernel = "linuxPackages_latest";
    shells = [];
    coding = [];
    common = [];
    launchers = [];
  };

  resolve = args:
    recursiveUpdate default (args.packages or {});

  resolvePackages = {
    host,
    pkgs,
  }: let
    groups = removeAttrs (host.packages or {}) ["kernel"];
    names = unique (concatLists (attrValues groups));
  in {
    kernel = let
      name = host.packages.kernel;
      err = "resolve host '${
        host.name
      }': kernel package '${name}' was not found in nixpkgs";
      package = pkgs.${name} or (throw err);
    in {inherit name package;};

    common = resolvePackageGroups {
      inherit pkgs;
      inherit groups names;
      context = "resolve host '${host.name}'";
    };
  };
in {
  inherit default resolve resolvePackages;
  resolveHostPackages = resolvePackages;
}
