{lib}: let
  inherit (lib.lists) elem optionals;
  inherit (lib.packages) mkPkgs;
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
  mkAISpec :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkAISpec {
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
  mkAISpec = {
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
      else throw "mkAISpec: unknown preset '${preset'}'. Valid: ${concatStringsSep ", " presets}";

    pkg = pkgs'.llm-agents;
    packages = {
      core = let
        minimal = with pkg; [default];
        common =
          minimal
          ++ (with pkg; [
            codex
            claude-code
            qwen-code
            openclaw
          ]);
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
        full = agents ++ assistants ++ vibe;
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

    env = {};

    shellHook = ''
      printf "🤖 AI"
      printf "    Preset: %s\n" "${preset'}"
    '';

    shell = {
      inherit name env shellHook;
      packages =
        []
        ++ packages.core
        ++ packages.utilities
        ++ packages.analytics
        ++ packages.workflow;
    };
  in {
    __meta = {
      kind = "ai";
      preset = preset';
      inherit packages env shellHook;
    };
    inherit shell;
  };

  mkAISuite = {pkgs ? null}: let
    mk = args: mkAISpec ({inherit pkgs;} // args);
  in {
    ai = mk {};
    #~@ Entry point
    ai-minimal = mk {
      preset = "minimal";
      includeAnalytics = false;
    };

    #~@ Focused suites
    ai-agents = mk {preset = "agents";};
    ai-assistants = mk {preset = "assistants";};

    #~@ Daily driver
    ai-common = mk {preset = "common";};

    #~@ Full suite — all agents + assistants + analytics + workflow
    ai-full = mk {
      preset = "full";
      includeWorkflow = true;
    };
  };
in {
  inherit mkAISpec mkAISuite;
  mkAI = mkAISpec;
  mkAIShells = mkAISuite;
}
