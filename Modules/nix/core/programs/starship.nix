{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "starship";
  cfg = config.${top}.${dom}.${mod};
  inherit (config.${top}.interface) shellPrompt;
  inherit (lix.types.options) mkEnable mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Starship Prompt";
      condition = shellPrompt == "starship";
    };
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      enable = true;
    };
  };
}
