{host, inputs, lix, ...}: let
  common = import ./common {inherit host inputs lix;};
  core = import ./core {inherit common;};
  home = import ./home {inherit common;};
in { inherit common core home; }
