{
  functionalities = import ./functionalities.nix;
  defaults = {
    stateVersion = "";
    system = "";
    class = "nixos";
    name = "";
    id = null;
    description = null;
    localization = import ./localization.nix;
    interface = import ./interface.nix;
    paths = import ./paths.nix;
    specs = {};
    packages = import ./packages.nix;
    principals = [];
  };
}
