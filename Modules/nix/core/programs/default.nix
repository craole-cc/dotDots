{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "system";
  mod = "programs";
  cfg = config.${top}.${dom}.${mod};
  user = host.users.data.primary or {};

  inherit (config.${top}.interface) shellPrompt shell;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options) mkTrue;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    vimKeybinds = mkOption {
      description = "Enable vim keybindings in shell";
      default = user.interface.keyboard.vimKeybinds or false;
      type = bool;
    };
    obs = mkTrue "OBS" // {default = true;};
  };

  config = mkIf cfg.enable {
    programs = {
      bash = mkIf (isIn "bash" ([shell] ++ (user.shells or []))) {
        enable = true;
        blesh.enable = true;
        undistractMe.enable = true;
      };

      direnv = {
        enable = true;
        silent = true;
        settings.global = {
          log_format = "-";
          log_filter = "^$";
          load_dotenv = true;
        };
      };

      starship.enable = shellPrompt == "starship";

      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      obs-studio = mkIf (isIn ["video" "webcam"] (host.functionalities or [])) {
        enable = true;
        enableVirtualCamera = cfg.obs;
      };

      xwayland.enable = true;
    };
  };
}
