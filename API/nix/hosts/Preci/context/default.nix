{
  host,
  inputs ? lix.inputs or {},
  lib,
  lix,
  ...
}: let
  data = import ./data {inherit lix lib host inputs;};
  core = import ./core data;
  home = import ./home data;
in {inherit data core home;}
