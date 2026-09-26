{
  defaults = {
    name = null;
    role = null;
    description = null;
    password = null;
    hashedPassword = null;
    enable = true;
    autoLogin = false;
    capabilities = {};
    localization = import ./localization.nix;
    identities = [];
    interface = import ./interface.nix;
    paths = import ./paths.nix;
    packages = import ./packages.nix;
  };
  capabilities = import ./capabilities.nix;
}
