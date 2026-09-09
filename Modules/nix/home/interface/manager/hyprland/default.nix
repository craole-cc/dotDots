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
      dmsEnabled = config.programs.dank-material-shell.enable or false;
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

    # Home Manager enables portal integration for the Hyprland profile. Since
    # xdg-desktop-portal >= 1.17 requires an explicit backend selection, keep
    # the traditional first-compatible-backend behaviour at the Home layer;
    # NixOS owns the detailed Hyprland/GTK portal routing.
    xdg.portal.config.common.default = "*";

    programs = mkAddons "programs";
    services = mkAddons "services";

    home.activation.removeLegacyHyprlandLua = lib.hm.dag.entryAfter ["writeBoundary"] ''
      legacy="$HOME/.config/hypr/hyprland.lua"
      if [ -e "$legacy" ] || [ -L "$legacy" ]; then
        rm -f "$legacy"
      fi
    '';

    # Old user-local portal descriptors shadow the NixOS-owned descriptors in
    # /run/current-system/sw/share/xdg-desktop-portal/portals. Remove only the
    # known stale copies; the system packages remain the source of truth.
    home.activation.removeLegacyUserPortalDescriptors = lib.hm.dag.entryAfter ["writeBoundary"] ''
      portal_dir="$HOME/.local/share/xdg-desktop-portal/portals"
      for portal in gtk.portal darkman.portal; do
        path="$portal_dir/$portal"
        if [ -e "$path" ] || [ -L "$path" ]; then
          rm -f "$path"
        fi
      done
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
