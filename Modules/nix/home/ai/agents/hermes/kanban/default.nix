{
  cfg,
  config,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) attrByPath attrNames;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.lists.predicates) all elem;
  inherit (lix.lists.selection) filter;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.types.combinators) attrsOf listOf nullOr;
  inherit (lix.types.primitives) anything int str;

  active = filterAttrs (_name: profile: profile.enable) cfg.profiles;
  known = name: name == "default" || active ? ${name};
  assignee = description:
    mkOption {
      type = nullOr str;
      default = null;
      inherit description;
    };
  limit = description:
    mkOption {
      type = int;
      default = 1;
      inherit description;
    };

  #? The gateway profile whose credentials the auxiliary decomposer actually
  #? uses. Upstream does not load the orchestrator's creds for decomposition.
  gatewayProfile = "default";

  #? Helper: does a profile have a credential source declared?
  #? Extracted here because the `or` operator only catches missing attrs on
  #? the immediate lhs, so `gp.auth.file or null` fails when gp is `{}`.
  hasCreds = profile:
    attrByPath ["auth" "file"] null profile
    != null
    || attrByPath ["environment" "files"] [] profile != [];
in {
  options.kanban = {
    enable = mkFalse "Enable Hermes Kanban task dispatch for the declared team.";
    profiles = mkOption {
      type = listOf str;
      default = ["default"] ++ attrNames active;
      description = "Profiles the dispatcher may assign work to. An empty list explicitly admits no workers.";
    };
    orchestrator = assignee "Profile owning orchestration tasks. Null uses the default profile.";
    defaultAssignee = assignee "Assignee for unassigned tasks and unmatched decomposition choices. Null explicitly selects the default profile.";
    concurrency = {
      total = limit "Maximum concurrent Kanban workers across the host.";
      perProfile = limit "Maximum concurrent Kanban workers for one profile.";
    };
    decomposition = {
      enable = mkFalse "Automatically decompose triage tasks. Hermes's planner sees all installed profiles, including profiles outside kanban.profiles.";
      model = mkOption {
        type = attrsOf anything;
        default = {};
        description = "Public auxiliary.kanban_decomposer settings, such as provider and model. Empty uses the main model.";
      };
    };
  };

  settings = optionalAttrs cfg.kanban.enable ({
      kanban = {
        dispatch_in_gateway = true;
        dispatch_profiles = cfg.kanban.profiles;
        max_in_progress = cfg.kanban.concurrency.total;
        max_in_progress_per_profile = cfg.kanban.concurrency.perProfile;
        auto_decompose = cfg.kanban.decomposition.enable;
        orchestrator_profile =
          if cfg.kanban.orchestrator == null
          then "default"
          else cfg.kanban.orchestrator;
        default_assignee =
          if cfg.kanban.defaultAssignee == null
          then "default"
          else cfg.kanban.defaultAssignee;
      };
    }
    // optionalAttrs (cfg.kanban.decomposition.model != {}) {
      auxiliary.kanban_decomposer = cfg.kanban.decomposition.model;
    });

  outputs.assertions = [
    {
      assertion = !cfg.kanban.enable || (cfg.gateway.multiplex && config.services.hermes-agent.gateway.enable);
      message = "Hermes Kanban dispatch requires gateway.multiplex and an enabled gateway service.";
    }
    {
      assertion = !cfg.kanban.enable || all known (cfg.kanban.profiles ++ (filter (name: name != null) [cfg.kanban.orchestrator cfg.kanban.defaultAssignee]));
      message = "Hermes Kanban workers and assignees must reference default or enabled declared profiles.";
    }
    {
      assertion =
        !cfg.kanban.enable
        || cfg.kanban.profiles == []
        || all (name: elem name cfg.kanban.profiles) [
          (
            if cfg.kanban.orchestrator == null
            then "default"
            else cfg.kanban.orchestrator
          )
          (
            if cfg.kanban.defaultAssignee == null
            then "default"
            else cfg.kanban.defaultAssignee
          )
        ];
      message = "Hermes Kanban orchestration and fallback assignees must be included in kanban.profiles, or dispatch must be explicitly paused with an empty list.";
    }
    {
      assertion = cfg.kanban.concurrency.total > 0 && cfg.kanban.concurrency.perProfile > 0;
      message = "Hermes Kanban concurrency limits must be positive integers.";
    }
    #? Decomposition uses the gateway profile's credentials, not the orchestrator's.
    #? Fail at eval time rather than at first plan.
    {
      assertion =
        !cfg.kanban.enable
        || !cfg.kanban.decomposition.enable
        || cfg.kanban.decomposition.model == {}
        || hasCreds (active.${gatewayProfile} or {});
      message = "Hermes Kanban decomposition is enabled, but the gateway profile ('${gatewayProfile}') has no auth.file or environment.files. The auxiliary decomposer uses the gateway profile's credentials, not the orchestrator's.";
    }
    #? Orchestration requires the orchestrator to be reachable as a Bot.
    {
      assertion =
        !cfg.kanban.enable
        || cfg.kanban.orchestrator == null
        || (active ? ${cfg.kanban.orchestrator} && active.${cfg.kanban.orchestrator}.bot.enable);
      message = "Hermes Kanban orchestrator '${cfg.kanban.orchestrator}' must be an enabled declared profile with bot.enable = true.";
    }
  ];
}
