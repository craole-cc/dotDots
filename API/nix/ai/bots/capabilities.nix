{
  lix,
  homePath,
  role,
  ...
}: let
  common = ["hermes-agent" "hermes-agent-docs" "sh-utils" "plan-first" "writing-style"];
  engineering = ["nix-style" "nix-inspect" "commit-messages" "systematic-debugging" "github" "gh-address-comments" "gh-fix-ci"];
  allowed = {
    receptionist = ["hermes-agent" "hermes-agent-docs" "writing-style"];
    coordinator = common ++ ["document-to-action-items"];
    intern = common ++ ["codebase-inspection" "grounded-citations"];
    scribe = common ++ engineering ++ ["test-driven-development"];
    developer = common ++ engineering ++ ["spike" "test-driven-development"];
    architect = common ++ ["architecture-diagram" "grounded-citations" "nix-inspect"];
    auditor = common ++ engineering ++ ["sdlc-review" "grounded-citations"];
  };
  budgets = {
    receptionist = 12;
    coordinator = 12;
    intern = 30;
    architect = 30;
    developer = 60;
    scribe = 60;
    auditor = 30;
  };
  managed = allowed ? ${role};
  readOnly = role == "architect";
  # Coordinator routes work and must be able to retrieve a worker's return, so it
  # needs `process_manage`, which ships only with the terminal toolset. Architect
  # stays read-only without it.
  toolsets =
    if readOnly
    then ["repository_read" "skills" "kanban"]
    else if role == "coordinator"
    then ["repository_read" "skills" "kanban" "terminal"]
    else ["file" "terminal" "skills" "kanban"];
in
  if !managed
  then {}
  else {
    settings = {
      kanban = {
        dispatch_in_gateway = false;
        auto_decompose = false;
        auto_subscribe_on_create = false;
        notify_in_gateway = false;
      };
      platform_toolsets = {
        cli = toolsets;
        telegram = toolsets;
        api_server = toolsets;
      };
      skills = {
        allowed = allowed.${role};
        external_dirs = ["${homePath}/skills"];
      };
      agent = {
        max_turns = budgets.${role};
        budget_warning_ratio = 0.7;
        disabled_toolsets =
          ["delegation"]
          ++ (
            if readOnly
            then ["terminal" "code_execution" "browser" "computer_use" "cronjob" "memory" "image_gen" "video_gen" "tts" "stt"]
            else []
          );
      };
      plugins = {
        enabled = [];
        disabled = ["advanced-delegation" "disk-cleanup" "memory-wiki"];
      };
    };
  }
