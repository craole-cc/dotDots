{lib}: let
  inherit (lib.lists) elem optionals;
  inherit (lib.packages) mkPkgs;
  inherit (lib.shells) mkAliasPackage mkMissionControl mkScriptPackage;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) isEmpty isNotEmpty;

  presets = [
    "common"
    "agents"
    "anthropic"
    "assistants"
    "full"
    "google"
    "minimal"
    "openai"
    "vibe"
  ];

  /**
  Build the AI-focused shell specification.

  # Type
  ```nix
  mkSpec :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkSpec {
    inherit pkgs;
    preset = "common";
  }
  # => {
  #   __meta.kind = "ai";
  #   shell.name = "ai-common";
  #   ...
  # }
  ```

  # Returns
  A shell spec containing AI agent packages, utilities, and shell initialization.
  */
  mkSpec = {
    pkgs ? null,
    preset ? null,
    includeAnalytics ? true,
    includeWorkflow ? false,
    minimal ? false,
  }: let
    pkgs' =
      if isNotEmpty pkgs
      then pkgs
      else mkPkgs {};

    preset' =
      if isEmpty preset
      then "common"
      else preset;

    name =
      if elem preset' presets
      then "ai-${preset'}"
      else throw "mkSpec: unknown preset '${preset'}'. Valid: ${concatStringsSep ", " presets}";

    env = {};

    pkg = pkgs'.llm-agents;

    scripts = {
      commands = mkScriptPackage {
        pkgs = pkgs';
        name = "ai-commands";
        file = ./commands.sh;
      };

      welcome = mkScriptPackage {
        pkgs = pkgs';
        name = "ai-welcome";
        file = ./welcome.sh;
        env = {
          AI_PRESET = preset';
          GUM = "${pkgs'.gum}/bin/gum";
        };
      };
    };

    missionCommands = {
      agents = {
        description = "Run agentsview when available";
        run = ''exec ai-command agents "$@"'';
      };
      claude = {
        description = "Run claude-code when available";
        run = ''exec ai-command claude "$@"'';
      };
      codex = {
        description = "Run codex when available";
        run = ''exec ai-command codex "$@"'';
      };
      doctor = {
        description = "Show which AI tools are available";
        run = ''exec ai-command doctor "$@"'';
      };
      gemini = {
        description = "Run gemini when available";
        run = ''exec ai-command gemini "$@"'';
      };
      goose = {
        description = "Run goose-cli when available";
        run = ''exec ai-command goose "$@"'';
      };
      opencode = {
        description = "Run opencode when available";
        run = ''exec ai-command opencode "$@"'';
      };
      usage = {
        description = "Run ccusage when available";
        run = ''exec ai-command usage "$@"'';
      };
    };
    missionControl = mkMissionControl {
      pkgs = pkgs';
      shellName = name;
      commands = missionCommands;
    };
    commandsAlias = mkAliasPackage {
      pkgs = pkgs';
      name = "commands";
      target = "${missionControl}/bin/mission-control";
    };
    mcAlias = mkAliasPackage {
      pkgs = pkgs';
      name = "mc";
      target = "${missionControl}/bin/mission-control";
    };

    packages = {
      core = let
        minimal = with pkg; [default];
        common =
          minimal
          ++ (with pkgs'; [ollama])
          ++ (with pkg; [codex claude-code]);
        agents = with pkg; [
          claude-code
          codex
          gemini-cli
          opencode
          qwen-code
          goose-cli
        ];
        anthropic = with pkg; [
          claude-code
          claude-code-router
          claude-plugins
          oh-my-claudecode
        ];
        google = with pkg; [gemini-cli];
        openai = with pkg; [
          codex
          code
          codex-acp
          copilot-cli
          copilot-language-server
        ];
        assistants = with pkg; [
          openclaw
          zeroclaw
          claw-code
          auto-claude
          claude-code-router
        ];
        vibe = with pkg; [
          vibe-kanban
          mistral-vibe
          cursor-agent
        ];
        full = minimal ++ agents ++ assistants ++ anthropic ++ openai ++ vibe;
      in
        {
          inherit
            agents
            common
            anthropic
            assistants
            full
            google
            minimal
            openai
            vibe
            ;
        }.${
          preset'
        };

      utilities = optionals (!minimal) (with pkgs'; [
        #~@ General
        git
        jq
        ripgrep
        curl
      ]);

      analytics = optionals (includeAnalytics && !minimal) (with pkg; [
        #~@ Usage & Visibility
        ccusage
        agentsview
      ]);

      workflow = optionals (includeWorkflow && !minimal) (with pkg; [
        #~@ Project Management
        vibe-kanban
      ]);
    };

    payloadPackages =
      []
      ++ packages.core
      ++ packages.utilities
      ++ packages.analytics
      ++ packages.workflow;

    controlPackages = [
      scripts.welcome
      scripts.commands
      missionControl
      commandsAlias
      mcAlias
    ];

    #> Shell hook includes auto-deployment of templates
    shellHook = ''${scripts.welcome}/bin/ai-welcome '';

    shell = {
      inherit name env shellHook;
      packages = controlPackages ++ payloadPackages;
    };
  in {
    __meta = {
      kind = "ai";
      preset = preset';
      inherit (scripts) commands;
      inherit controlPackages env missionCommands packages payloadPackages shellHook;
    };
    inherit shell;
  };
in {
  inherit mkSpec;
  mkAISpec = mkSpec;
  mkShell = mkSpec;
}
