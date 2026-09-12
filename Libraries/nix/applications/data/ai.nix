_: {
  chatgpt = {
    aliases = [
      "openai"
      "chatgpt-desktop"
    ];
    package = {
      source = "ai";
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
      source = "ai";
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
      source = "ai";
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
}
