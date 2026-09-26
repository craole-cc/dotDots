{host, inputs, lix, ...}: let
  common = import ./common.nix {
    inherit host inputs lix;
  };

  core = {
    functionalities = common.functionalities;
    packages = common.packages;
  };

  home = common.principals;
in {
  inherit common core home;
}
