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
    git = import ./git.nix;
    localization = import ./localization.nix;
    identities = [];
    interface = import ./interface.nix;
    applications = import ./applications.nix;
    paths = import ./paths.nix;
    packages = import ./packages.nix;
  };

  capabilities = import ./capabilities.nix;
  capabilityRequirements = import ./capability-requirements.nix;
}
