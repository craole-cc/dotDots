{capabilities, packages, ...}: {
  resolve = {
    host,
    user,
  }: let
    capabilityResolution = capabilities.resolve {
      inherit host user;
    };
    packageResolution = packages.resolveUser {
      pkgs = packages.pkgs;
      inherit user;
    };
  in
    user
    // {
      resolution = {
        inherit capabilityResolution packageResolution;
        capabilities = capabilityResolution;
        packages = packageResolution;
      };
    };
}
