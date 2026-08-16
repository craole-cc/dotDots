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
  cfg = config.${top}.resolved.${dom}.${mod};
  cfgTop = nixosConfig.${top}.resolved;
  #> Use user.interface directly - already normalized per-user in mkUsers
  inherit (user.interface) windowManager;

  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.modules.core.staging) mkStaged;
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

    home.activation.normalizeDmsHyprlandOutputs = lib.hm.dag.entryAfter ["writeBoundary"] ''
            outputs="$HOME/.config/hypr/dms/outputs.conf"
            mkdir -p "$(dirname "$outputs")"
            cat > "$outputs" <<'EOF_DMS_OUTPUTS'
      # Managed by Home Manager; keep monitor syntax compatible with Hyprland.
      monitor = eDP-1, 1920x1080@144, 0x0, 1
      monitor = HDMI-A-1, 1920x1080@100, 0x1080, 1
      EOF_DMS_OUTPUTS
    '';
  };
in {
  options.${top}.resolved.${dom}.${mod} = {
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
