{lix, ...}: let
  resolveFunctionalities = functionalities:
    lix.attrsets.genAttrs
    functionalities
    (_: true);
in {
  resolve = {
    host,
    packages,
  }:
    host
    // {
      resolution = {
        functionalities = resolveFunctionalities host.functionalities;
        packages = packages.resolveHost {
          inherit host;
          pkgs = packages.pkgs;
        };
      };
    };
}
