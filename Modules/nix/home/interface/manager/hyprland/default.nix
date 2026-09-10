{
  config,
  host,
  lib,
  lix,
  pkgs,
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

  dmsEnabled = config.programs.dank-material-shell.enable or false;
  dmsEmbedded = "${pkgs.dms-shell.src}/core/internal/config/embedded";
  dmsRoot = pkgs.runCommand "dms-hyprland.lua" {} ''
    ${pkgs.gnused}/bin/sed \
      '/-- DMS_STARTUP_BEGIN/,/-- DMS_STARTUP_END/d' \
      ${dmsEmbedded}/hyprland.lua > "$out"
  '';
  dmsBinds = pkgs.runCommand "dms-hypr-binds.lua" {} ''
    substitute \
      ${dmsEmbedded}/hypr-binds.lua \
      "$out" \
      --replace-fail \
        '{{TERMINAL_COMMAND}}' \
        ${lib.escapeShellArg apps.terminal.primary.command}
  '';

  mkAddons = target:
    mkIf cfg.withAddons (import ./addons {
      inherit lib mkMerge dmsEnabled;
    }).${target};

  payload = {
    wayland.windowManager.hyprland = mkMerge [
      {
        # DMS 1.6 owns the active Lua configuration contract. The legacy Home
        # Manager tree remains available when DMS is not selected, but must not
        # recreate hyprland.conf alongside the DMS Lua tree.
        enable = cfg.enable && !dmsEnabled;
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

    # DMS's compositor setup is intentionally not part of the runtime workflow.
    # Materialize the DMS 1.6 Lua entrypoint from the exact dms-shell package
    # source selected by Nix. UWSM owns session activation, so strip DMS's
    # legacy hyprland-session.target hook from the upstream template. DMS owns
    # writable dms/*.lua state; Nix seeds it when absent and refreshes only the
    # DMS-owned default binds.
    home.activation.materializeDmsHyprlandLua = mkIf dmsEnabled (lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_dir=${lib.escapeShellArg config.xdg.configHome}/hypr
      dms_dir="$config_dir/dms"

      ${pkgs.coreutils}/bin/mkdir -p "$dms_dir"
      ${pkgs.coreutils}/bin/install -m 0644 ${dmsRoot} "$config_dir/hyprland.lua"
      ${pkgs.coreutils}/bin/install -m 0644 ${dmsBinds} "$dms_dir/binds.lua"

      seed() {
        src="$1"
        dst="$2"
        if [ ! -s "$dst" ]; then
          ${pkgs.coreutils}/bin/install -m 0644 "$src" "$dst"
        fi
      }

      seed ${dmsEmbedded}/hypr-binds-user.lua "$dms_dir/binds-user.lua"
      seed ${dmsEmbedded}/hypr-colors.lua "$dms_dir/colors.lua"
      seed ${dmsEmbedded}/hypr-cursor.lua "$dms_dir/cursor.lua"
      seed ${dmsEmbedded}/hypr-layout.lua "$dms_dir/layout.lua"
      seed ${dmsEmbedded}/hypr-outputs.lua "$dms_dir/outputs.lua"
      seed ${dmsEmbedded}/hypr-windowrules.lua "$dms_dir/windowrules.lua"
    '');

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
