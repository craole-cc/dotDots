{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  bots = import ./bots {
    inherit lix homeDirectory homePath;
    definitions.hermes = ./bots/hermes;
    enabled = ["hermes"];
  };
in
  bots
  // {
    gateway.multiplex = false;
    kanban.enable = false;
  }
