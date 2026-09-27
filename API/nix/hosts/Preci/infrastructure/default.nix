{
  host,
  inputs ? lix.inputs or {},
  lib,
  lix,
  ...
}: let
  common = import ./common {inherit lix lib host inputs;};
  core = import ./core common;
  home = import ./home common;
in {inherit common core home;}
