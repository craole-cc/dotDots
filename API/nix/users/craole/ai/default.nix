{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  inherit (lix.schema.construction) mkSchema;
  bots = (mkSchema {}).ai.bots {
    inherit lix homeDirectory homePath;
    enabled = ["hermes" "coordinator" "developer" "librarian" "anthropologist" "assistant" "architect" "scribe" "intern" "auditor"];
  };
in
  bots
  // {
    gateway.multiplex = true;
    kanban.enable = false;
  }
