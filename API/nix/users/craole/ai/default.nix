{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  inherit (lix.schema.construction) mkSchema;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.transformation) filter;
  credentials = concat {
    root = homeDirectory;
    stem = (mkSchema {}).paths.stems.home.private ++ ["hermes" "deepseek.env"];
  };
  bots = (mkSchema {}).ai.bots {
    inherit lix homeDirectory homePath;
    environmentFiles = filter pathExists [credentials];
    default = "receptionist";
    enabled = ["receptionist" "coordinator" "developer" "librarian" "anthropologist" "assistant" "architect" "scribe" "intern" "auditor"];
  };
in
  bots
  // {
    gateway.multiplex = true;
    kanban.enable = false;
  }
