{lix, ...}: let
  resolveFunctionalities = functionalities:
    lix.attrsets.genAttrs
    functionalities
    (_: true);
in {
  resolve = {
    host,
    packages,
  }: {
    name = host.name;
    class = host.class;
    functionalities = resolveFunctionalities host.functionalities;
    interface = host.interface;
    localization = host.localization;
    paths = host.paths;
    packages = packages.resolveHost {
      inherit host;
      pkgs = packages.pkgs;
    };
  };
}
