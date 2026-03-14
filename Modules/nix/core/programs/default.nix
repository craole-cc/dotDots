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

  iface = config.${top}.interface;
  wm = iface.wm;
  prompt = iface.prompt or null;
  shell = iface.shell or null;

  user = host.users.data.primary or {};

  inherit (lix.lists.predicates) isIn;
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
    virtualCamera = mkOption {
      description = "Enable OBS virtual camera";
      default = true;
      type = bool;
    };
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

      starship.enable = prompt == "starship";

      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      obs-studio = mkIf (isIn ["video" "webcam"] (host.functionalities or [])) {
        enable = true;
        enableVirtualCamera = cfg.virtualCamera;
      };

      xwayland.enable = true;
    };
  };
}
