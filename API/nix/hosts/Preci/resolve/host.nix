{lix, ...}: let
  inherit (lix.attrsets) genAttrs;

  resolveFunctionalities = functionalities:
    genAttrs
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
