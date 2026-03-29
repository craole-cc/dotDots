{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "starship";
  cfg = config.${top}.${dom}.${mod};
  # inherit (config.${top}.interface) shellPrompt;
  inherit (lix.types.options) mkEnable mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Starship Prompt";
      # condition = shellPrompt == "starship";
      condition = true;
    };
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable;
    };
  };
}
