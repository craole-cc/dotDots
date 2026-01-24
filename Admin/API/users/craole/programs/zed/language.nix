{
  programs.zed-editor.userSettings = {
    #| AI & Assistant Features
    assistant = {
      version = "2";
      enabled = true;
      button = true;
      dock = "bottom";
      default_width = 640;
      default_height = 320;
      default_model = {
        provider = "ollama";
        model = "qwen2.5-coder:latest";
      };
    };
    language_models = {
      anthropic.version = "1";
      anthropic.api_url = "https://api.anthropic.com";
      google.api_url = "https://generativelanguage.googleapis.com";
      ollama = {
        api_url = "http://localhost:11434";
        low_speed_timeout_in_seconds = 60;
      };
      openai = {
        version = "1";
        api_url = "https://api.openai.com/v1";
        low_speed_timeout_in_seconds = 600;
      };
    };

    #| Language Integrations
    enable_language_server = true;
    language_servers = ["..."];
    languages = {};
    jupyter.enabled = true;
    code_actions_on_format = {};
  };
}
