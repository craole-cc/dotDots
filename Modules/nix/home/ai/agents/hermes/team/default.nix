{
  config,
  lix,
  homePath,
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;

  #? Single source of truth for memory settings.
  inherit (import ../settings {}) memory;

  keys = rec {
    home = "${config.home.homeDirectory}/Private/hermes";
    files = {
      deepseek = ["${home}/deepseek.env"];
      nvidia = ["${home}/nvidia.env"];
      openrouter = ["${home}/openrouter.env"];
      huggingface = ["${home}/huggingface.env"];
      ninerouter = ["${home}/ninerouter.env"];
    };
    #? openai-codex authenticates through auth.json, so it has no entry here.
    for = provider: files.${provider} or [];
  };

  models = {
    default = models.gpt.flash;
    gpt = {
      flash = {
        provider = "openai-codex";
        default = "gpt-6-luna";
      };
      smart = {
        provider = "openai-codex";
        default = "gpt-6.1-sol";
      };
    };
    deepseek = {
      flash = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
      smart = {
        provider = "deepseek";
        default = "deepseek-v4-pro";
      };
    };
  };

  #? Luna for routing and gathering, sol where mistakes are expensive.
  team = {
    receptionist = {
      description = "Receive requests, clarify requirements and hand tasks to the planner.";
      settings.model = models.gpt.flash;
      terse.level = "full";
      home.file."SOUL.md" = "Keep replies brief. Record clear Kanban tasks for planner; specialists perform substantive work.";
    };
    researcher = {
      description = "Research questions and provide source-backed findings.";
      settings.model = models.gpt.flash;
    };
    planner = {
      description = "Plan task graphs, coordinate specialists and synthesise results.";
      settings.model = models.gpt.smart;
    };
    coder = {
      description = "Implement scoped changes and record evidence for review.";
      settings.model = models.deepseek.flash;
    };
    reviewer = {
      description = "Review changes for correctness and report actionable findings.";
      settings.model = models.gpt.smart;
    };
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

  starters =
    mapAttrs (
      _: profile:
        recursiveUpdate {
          bot.enable = true;
          #? Runtime string paths seed writable auth files; credentials never enter Nix.
          auth.file = "${homePath}/auth.json";
          environment.files = keys.for (profile.settings.model.provider or models.default.provider);
          settings = {
            inherit memory;
            model = models.default;
          };
        }
        profile
    )
    team;
in {
  inherit models;
  profiles = adopted // starters;
}
