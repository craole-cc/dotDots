{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues recursiveUpdate;
  inherit (lib.lists) concatLists unique;
  inherit (lix.attrsets) resolvePackage;
  inherit (lix.trivial) isNotEmpty;

  default = {
    kernel = "linuxPackages_latest";
    shells = [];
    coding = [];
    common = [];
    launchers = [];
  };

  resolve = {
    pkgs,
    args,
  }: let
    context = "resolve packages for host:'${args.name}'";
    groups = attrNames default;
    names = unique (concatLists (attrValues default));
    packages = recursiveUpdate default (args.packages or args);
  in {
    kernel = let
      name = packages.kernel;
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
    common = resolvePackageGroups {inherit context groups names pkgs;};
  };
in {inherit default resolve;}
