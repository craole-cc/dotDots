{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    loadModels = [
      "codegemma:7b"
      "qwen2.5-coder"
    ];
  };

  environment.systemPackages = with pkgs; [
    gpt4all
  ];
}
