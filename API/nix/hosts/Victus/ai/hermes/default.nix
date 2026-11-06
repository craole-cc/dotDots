#TODO: This needs to be reviewed. it seems ad-hoc
{
  config,
  lix,
  host,
  osConfig ? {},
  ...
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;

  localModel = {
    provider = "ollama";
    default =
      osConfig._.resolved.ai.agents.ollama.defined.models.chat.default or (
        # TODO: This needs to be resolved the same way we did the osConfig one. We need a real ollama home-manager config
        host.ai.ollama.models.chat.default or null
      );
    base_url = "http://127.0.0.1:11434/v1";
  };
  memory = {
    memory_enabled = true;
    user_profile_enabled = true;
    provider = "";
  };
  cloudModel = {
    provider = "openai-codex";
    default = "gpt-5.6-terra";
  };
  team = {
    receptionist = {
      description = "Receive requests, clarify requirements and hand tasks to the planner.";
      settings.model = localModel;
      home.file."SOUL.md" = "Keep replies brief. Record clear Kanban tasks for planner; specialists perform substantive work.";
    };
    planner.description = "Plan task graphs, coordinate specialists and synthesise results.";
    coder.description = "Implement scoped changes and record evidence for review.";
    researcher.description = "Research questions and provide source-backed findings.";
    reviewer.description = "Review changes for correctness and report actionable findings.";
  };
  # Adopt the installed roster as well: upstream automatic planning sees every
  # installed profile, so every current candidate must be an admitted worker.
  existing = [
    "accessibility-auditor"
    "api-designer"
    "architect"
    "backend-engineer"
    "code-reviewer"
    "cole-bassed"
    "data-analyst"
    "debugger"
    "dev"
    "devops-engineer"
    "doc-writer"
    "frontend-engineer"
    "glm-analyst"
    "incident-responder"
    "lab"
    "ling-translator"
    "local"
    "performance-optimiser"
    "prompt-engineer"
    "refactorer"
    "research"
    "safe-gateway"
    "security-auditor"
    "sql-expert"
    "test-writer"
    "writing"
  ];
  adopted = genAttrs existing (_: {
    bot.enable = true;
    settings = {inherit memory;};
  });
  starters = mapAttrs (_: profile:
    recursiveUpdate {
      bot.enable = true;
      # Runtime string paths seed writable auth files; credentials never enter Nix.
      auth.file = "${config._.resolved.ai.agents.hermes-agent.defined.home.path}/auth.json";
      settings = {
        inherit memory;
        model = cloudModel;
      };
    }
    profile)
  team;
in {
  _.resolved.ai.agents.hermes-agent.defined = {
    enable = true;
    desktop.enable = true;
    gateway.enable = true;
    extra.dependencyGroups = ["messaging"];
    settings = {
      inherit memory;
      model = localModel;
    };
    profiles =
      adopted
      // starters
      // {
        local =
          adopted.local
          // {
            settings = {
              inherit memory;
              model = localModel;
            };
          };
      };
    gateway.multiplex = true;
    kanban = {
      enable = true;
      orchestrator = "planner";
      defaultAssignee = "planner";
      concurrency = {
        total = 1;
        perProfile = 1;
      };
      decomposition = {
        enable = false;
        model = {
          provider = "openai-codex";
          model = "gpt-6.1-sol";
        };
      };
    };
  };
}
