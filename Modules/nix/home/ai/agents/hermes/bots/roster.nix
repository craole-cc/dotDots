{
  config,
  lix,
  models,
  memory,
  homePath,
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.transformation) filter;
  keysFor = provider: filter pathExists ["${config.home.homeDirectory}/Private/hermes/${provider}.env"];
  #? Luna for routing and gathering, sol where mistakes are expensive.
  roster = {
    receptionist = {
      description = "Receive requests, clarify requirements and hand tasks to the planner.";
      settings.model = models.gpt.flash;
      terse.level = "full";
      home.file."SOUL.md" = "Keep replies brief. Record clear Kanban tasks for planner; specialists perform substantive work.";
    };
    researcher = {
      description = "Research questions and provide source-backed findings.";
      settings.model = models.default.flash;
    };
    planner = {
      description = "Plan task graphs, coordinate specialists and synthesise results.";
      settings.model = models.default.smart;
    };
    coder = {
      description = "Implement scoped changes and record evidence for review.";
      settings.model = models.deepseek.flash;
    };
    reviewer = {
      description = "Review changes for correctness and report actionable findings.";
      settings.model = models.deepseek.smart;
    };
  };

  # Adopt the installed roster as well: upstream automatic planning sees every
  # installed profile, so every current candidate must be an admitted worker.
  installed = [
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

  adopted = genAttrs installed (_: {
    bot.enable = true;
    settings = {inherit memory;};
  });

  starters = mapAttrs (_: profile:
    recursiveUpdate {
      bot.enable = true;
      #? Runtime string paths seed writable auth files; credentials never enter Nix.
      auth.file = "${homePath}/auth.json";
      environment.files = keysFor (profile.settings.model.provider or models.default.flash.provider);
      settings = {
        inherit memory;
        model = models.default.flash;
      };
    }
    profile)
  roster;
in
  adopted // starters
