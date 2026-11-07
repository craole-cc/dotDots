{
  lix,
  homeDirectory,
  ...
}: let
  homePath = "${homeDirectory}/Projects/hermes";
  bots = import ./bots {
    inherit lix homeDirectory homePath;
    definitions.hermes = ./bots/hermes;
    enabled = ["hermes"];
  };
in
  bots
  // {
    home = bots.home // {path = homePath;};
    workingDirectory = homePath;
    gateway.multiplex = false;
    kanban.enable = false;
  }
