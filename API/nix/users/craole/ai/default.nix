{
  lix,
  homeDirectory,
  homePath,
  ...
}: let
  inherit (lix.schema.construction) mkSchema;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
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
  recursiveUpdate bots {
    credentials.sources = ["${private}/hermes.env" "${private}/hermes/.env" "${private}/hermes/*.env"];
    gateway = {
      multiplex = true;
      telegram.source = "${private}/hermes/.env";
    };
    handoff.enable = true;
    kanban = {
      enable = false;
      profiles = ["coordinator" "developer" "architect" "scribe" "intern" "auditor"];
      orchestrator = "coordinator";
      defaultAssignee = "developer";
      concurrency = {
        total = 1;
        perProfile = 1;
      };
    };
    settings.kanban = {
      dispatch_in_gateway = false;
      dispatch_profiles = [];
      auto_decompose = false;
      auto_subscribe_on_create = true;
      completion_delivery_mode = "notify";
      notify_in_gateway = true;
      max_in_progress = 1;
      max_in_progress_per_profile = 1;
      failure_limit = 2;
      execution_limits = {
        enabled = true;
        require_independent_review = true;
        review_profiles = ["developer" "architect" "scribe"];
        max_runs = 8;
        max_correction_rounds = 2;
      };
    };
    knowledge = {
      enable = true;
      root = "${homeDirectory}/Projects/craole-cc/ccki";
    };
  }
