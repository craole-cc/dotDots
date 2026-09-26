{capabilities, packages, ...}: {
  resolve = {
    host,
    user,
  }:
    user
    // {
      resolution = {
        capabilities = capabilities.resolve {inherit host user;};
        packages = packages.resolveUser {
          pkgs = packages.pkgs;
          inherit user;
        };
      };
    };
}
