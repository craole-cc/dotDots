{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "continue";
  condition = requires mod;
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = ["Continue.continue"];

  settings.${mod} = {
    continue = {
      telemetryEnabled = false;
      disableQuickFix = true;
      enableTabAutocomplete = true;
      showInlineTip = false;
    };
  };
in {inherit enable extensions options settings;}
