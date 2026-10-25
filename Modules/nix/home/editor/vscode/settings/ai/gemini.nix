{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "gemini";
  condition = requires [mod "google"];
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = [];
  settings = {
    geminicodeassist = {
      chat.defaultCodeBlockDisplay = "Expanded";
      inlineSuggestions.enableAuto = true;
      updateChannel = "Insiders";
    };
  };
in {inherit enable options extensions settings;}
