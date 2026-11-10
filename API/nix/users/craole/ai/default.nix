{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  inherit (lix.schema.construction) mkSchema;
  inherit (lix.filesystem.primitives) concat;
  private = concat {
    root = homeDirectory;
    stem = (mkSchema {}).paths.stems.home.private;
  };
  bots = (mkSchema {}).ai.bots {
    inherit lix homeDirectory homePath;
    environmentFiles = ["${homePath}/credentials.env"];
    default = "receptionist";
    enabled = ["receptionist" "coordinator" "developer" "librarian" "anthropologist" "assistant" "architect" "scribe" "intern" "auditor"];
  };
in
  bots
  // {
    credentials.sources = ["${private}/hermes.env" "${private}/hermes/.env" "${private}/hermes/*.env"];
    gateway = {
      multiplex = true;
      telegram.source = "${private}/hermes/.env";
    };
    handoff.enable = true;
    kanban.enable = false;
    knowledge = {
      enable = true;
      root = "${homeDirectory}/Projects/craole-cc/ccki";
    };
  }
