{...}: let
  args = import ./args.nix;
  lix = import ./lib {};
  inputs = import ./inputs {
    inherit lix;
    inherit (args) system;
  };
  host = lix.mkHost args;
  infrastructure = import ./infrastructure {
    inherit host inputs lix;
  };
in {
  imports =
    inputs.modules
    ++ [
      ./outputs
    ];

  _module.args = {
    inherit host lix inputs infrastructure;
  };
}
