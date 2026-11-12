_: {
  chatgpt = {
    aliases = [
      "openai"
      "chatgpt-desktop"
    ];
    package = {
      source = "llm-agents";
      attribute = "chatgpt";
    };
    names = {
      package = "chatgpt";
      command = "chatgpt";
      title = "ChatGPT";
    };
    exec = "chatgpt";
    categories = ["ai"];
    family = "openai";
  };

  hermes-desktop = {
    aliases = [
      "hermes"
      "hermes-ui"
    ];
    package = {
      source = "llm-agents";
      attribute = "hermes-desktop";
    };
    names = {
      package = "hermes-desktop";
      command = "hermes-desktop";
      class = "hermes";
      title = "Hermes";
    };
    exec = "hermes-desktop";
    categories = ["ai"];
    family = "nous";
  };

  claude-desktop = {
    aliases = [
      "claude"
      "anthropic"
    ];
    package = {
      source = "llm-agents";
      attribute = "claude-desktop";
    };
    names = {
      package = "claude-desktop";
      command = "claude-desktop";
      class = "claude-desktop";
      title = "Claude";
    };
    exec = "claude-desktop";
    categories = ["ai"];
    family = "anthropic";
  };

  claude-code = {
    package = {
      source = "llm-agents";
      attribute = "claude-code";
    };
    names = {
      package = "claude-code";
      command = "claude";
      title = "Claude Code";
    };
    exec = "claude";
    needsTerminal = true;
    categories = ["ai"];
    family = "anthropic";
  };

  codex = {
    package = {
      source = "llm-agents";
      attribute = "codex";
    };
    names = {
      package = "codex";
      command = "codex";
      title = "Codex";
    };
    exec = "codex";
    needsTerminal = true;
    categories = ["ai"];
    family = "openai";
  };

  continue = {
    package.attribute = "vscode-extensions.continue.continue";
    names = {
      package = "continue";
      title = "Continue";
    };
    categories = ["ai"];
  };

  llmhop = {
    package = {
      source = "llmhop";
      attribute = "llmhop";
    };
    names = {
      package = "llmhop";
      command = "llmhop";
      title = "llmhop";
    };
    exec = "llmhop";
    needsTerminal = true;
    categories = ["ai"];
  };

  ollama = {
    names = {
      package = "ollama";
      command = "ollama";
      title = "Ollama";
    };
    exec = "ollama";
    needsTerminal = true;
    categories = ["ai"];
  };
}
