{
  config,
  host,
  lib,
  lix,
  top,
  user,
  apps,
  keyboard,
  paths,
  nixosConfig,
  ...
}: let
  dom = "interface";
  mod = "hyprland";
  cfg = config.${top}.inputs.${dom}.${mod};
  cfgTop = nixosConfig.${top}.inputs;
  #> Use user.interface directly - already normalized per-user in mkUsers
  inherit (user.interface) windowManager;

  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.modules.core._) mkStaged;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;

  mkAddons = target:
    mkIf cfg.withAddons
    (
      import ./addons {inherit lib mkMerge paths;}
    ).${
      target
    };

  payload = {
    wayland.windowManager.hyprland = mkMerge [
      {
        enable = true;
        configType = "hyprlang";
        plugins = [];
      }
      (import ./settings {
        inherit
          host
          lib
          lix
          apps
          user
          keyboard
          mkMerge
          ;
        inherit (cfg) withRules;
        keys = cfgTop.interface.keyboard;
      })
      (import ./submaps {inherit mkMerge;})
    ];

    programs = mkAddons "programs";
    services = mkAddons "services";

    home.activation.removeLegacyHyprlandLua = lib.hm.dag.entryAfter ["writeBoundary"] ''
      legacy="$HOME/.config/hypr/hyprland.lua"
      if [ -e "$legacy" ] || [ -L "$legacy" ]; then
        rm -f "$legacy"
      fi
    '';
  };
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = windowManager == "hyprland";};
    withAddons = mkOption {
      description = "Enable hyprland addons";
      default = true;
      type = bool;
    };
    withRules = mkEnableOption "Window rules" // {default = true;};
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
