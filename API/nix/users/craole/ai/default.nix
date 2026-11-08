{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  bots = import ./bots {
    inherit lix homeDirectory homePath;
    definitions = {
      hermes = ./bots/hermes;
      coordinator = ./bots/coordinator;
      developer = ./bots/developer;
      librarian = ./bots/librarian;
      anthropologist = ./bots/anthropologist;
      assistant = ./bots/assistant;
      architect = ./bots/architect;
      scribe = ./bots/scribe;
      intern = ./bots/intern;
      auditor = ./bots/auditor;
    };
    enabled = ["hermes" "coordinator" "developer" "librarian" "anthropologist" "assistant" "architect" "scribe" "intern" "auditor"];
  };
in
  bots
  // {
    gateway.multiplex = true;
    kanban.enable = false;
  }
