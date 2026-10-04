{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  inherit (lix.attrsets) attrValues;
  inherit (lix.lists) concatLists unique;
  inherit (lix.packages) resolvePackageGroups;

  default = {
    allowUnfree = true;
    kernel = "CachyOS"; # or "linuxPackages_latest"
    shells = ["bash"];
    coding = [];
    common = [];
    launchers = [];
  };

  resolve = args:
    recursiveUpdate default (args.packages or {});

  #? The host's own packages. The same shape as a principal's, and resolved the
  #? same way -- the pools and alias table are forwarded so a host package that a
  #? fetched source publishes resolves here too.
  #?
  #? The kernel is handled separately because it has its own resolution in
  #? `context/packages.nix`: it may need a loader rather than an attribute, and
  #? its variant ladder is host-specific. Keeping it out of `groups` stops
  #? `expandNames` treating a kernel name as a package group.
  resolvePackages = {
    host,
    pkgs,
    #? Named `pools` for the same reason as the user resolver: `extra` is a
    #? package group name, and a parameter of that name shadowed it.
    pools ? {},
    aliasOf ? name: null,
  }: let
    groups = removeAttrs (host.packages or {}) ["kernel"];
    names = unique (concatLists (attrValues groups));

    resolution = resolvePackageGroups {
      inherit pkgs groups names aliasOf;
      extra = pools;
      context = "resolve host '${host.name}'";
    };
  in {
    kernel = let
      name = host.packages.kernel;
      err = "resolve host '${
        host.name
      }': kernel package '${name}' was not found in nixpkgs";
      package = pkgs.${name} or (throw err);
    in {inherit name package;};

    common = resolution.packages;
    inherit (resolution) missing warnings;
  };
in {
  inherit default resolve resolvePackages;
  resolveHostPackages = resolvePackages;
}
