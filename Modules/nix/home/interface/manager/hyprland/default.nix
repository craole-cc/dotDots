{
  config,
  host,
  lib,
  lix,
  user,
  apps,
  keyboard,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "managers";
    mod = "hyprland";
  };
  inherit (context) cfg ctx;

  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) bool;

  mkAddons = target:
    mkIf cfg.withAddons (import ./addons {
      inherit lib mkMerge;
    }).${target};

  payload = {
    wayland.windowManager.hyprland = mkMerge [
      {
        enable = cfg.enable;
        configType = "hyprlang";
        plugins = [];

        # NixOS owns the Hyprland package and UWSM session. Home Manager's
        # Hyprland systemd integration creates a competing session target and
        # conflicts with programs.hyprland.withUWSM.
        package = null;
        systemd.enable = false;
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
        keys = user.interface.keyboard;
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
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsHyprland);
      withAddons = mkOption {
        description = "Enable Hyprland addons";
        default = true;
        type = bool;
      };
      withRules = mkEnable {
        description = "Hyprland window rules";
      };
    };
    outputs = payload;
  }
