{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "chatgpt";
  condition = requires [mod "codex"];
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = [
    "openai.chatgpt"
    "openai.codex-audio"
  ];
  settings = {};
in {inherit enable options extensions settings;}
