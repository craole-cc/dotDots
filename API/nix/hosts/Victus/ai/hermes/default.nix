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
    default = osConfig._.resolved.ai.agents.ollama.explicit.chat.active or host.ai.ollama.models.chat.active;
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
      hermesHomeFiles."SOUL.md" = "Keep replies brief. Record clear Kanban tasks for planner; specialists perform substantive work.";
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
      authFile = "${config.services.hermes-agent.hermesHome}/auth.json";
      settings = {
        inherit memory;
        model = cloudModel;
      };
    }
    profile)
  team;
in {
  _.resolved.ai.agents.hermes-agent.explicit = {
    enable = true;
    programs.desktop.enable = true;
    services = {
      gateway.enable = true;
      extraDependencyGroups = ["messaging"];
      settings = {
        inherit memory;
        model = localModel;
      };
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
    swarm = {
      enable = true;
      orchestrator = "planner";
      defaultAssignee = "planner";
      concurrency = {
        total = 1;
        perProfile = 1;
      };
      decomposition = {
        enable = true;
        model = {
          provider = "openai-codex";
          model = "gpt-5.6-terra";
        };
      };
    };
  };
}
