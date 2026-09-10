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

  # Scratchpads are an attrset keyed by workspace name. The schema owns the
  # default bindings while user/host API values may recursively override each
  # workspace's binding and startup list.
  scratchpads = user.interface.keyboard.scratchpads or {};

  mkDmsChord = scratchpad: let
    binding = scratchpad.binding or {};
  in
    lib.concatStringsSep " + " (
      builtins.filter (part: part != "") (lib.splitString " " (binding.mod or ""))
      ++ [binding.key]
    );

  mkDmsScratchpadBind = workspace: scratchpad: let
    binding = scratchpad.binding or {};
  in
    if (binding.key or null) == null
    then ""
    else let
      chord = mkDmsChord scratchpad;
    in ''
      -- Scratchpads own their chord. DMS defaults are loaded first, so remove
      -- any prior action (for example DMS's SUPER + M process-list binding).
      hl.unbind(${builtins.toJSON chord})
      hl.bind(${builtins.toJSON chord}, hl.dsp.workspace.toggle_special(${builtins.toJSON workspace}), { description = ${builtins.toJSON "Toggle ${workspace} workspace"} })
    '';

  mkDmsScratchpadStartup = workspace: scratchpad:
    lib.concatStringsSep "" (
      map (
        command: ''
          hl.exec_cmd(${builtins.toJSON "[workspace special:${workspace} silent] ${command}"})
        ''
      ) (scratchpad.startup or [])
    );

  dmsScratchpadStartup =
    lib.concatStringsSep "" (lib.mapAttrsToList mkDmsScratchpadStartup scratchpads);

  dmsDotBinds = pkgs.writeText "dms-hypr-binds-dots.lua" (
    ''
      -- dotDots declarative scratchpads.
      -- Defaults are schema-owned; user API overrides are already normalized.
      -- Inserted before DMS's mutable binds-user.lua so runtime overrides win.
    ''
    + lib.concatStringsSep "" (lib.mapAttrsToList mkDmsScratchpadBind scratchpads)
    + lib.optionalString (dmsScratchpadStartup != "") ''

      hl.on("hyprland.start", function()
      ${dmsScratchpadStartup}end)
    ''
  );

  dmsRoot = pkgs.runCommand "dms-hyprland.lua" {} ''
    ${pkgs.gnused}/bin/sed \
      '/-- DMS_STARTUP_BEGIN/,/-- DMS_STARTUP_END/d' \
      ${dmsEmbedded}/hyprland.lua \
      | ${pkgs.gawk}/bin/awk -v binds=${lib.escapeShellArg dmsDotBinds} '
          /require\("dms.binds-user"\)/ {
            while ((getline line < binds) > 0) print line
            close(binds)
          }
          { print }
        ' > "$out"
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
    # Materialize all dependencies before atomically replacing the active Lua
    # entrypoint. Hyprland watches this path, so replacing it last avoids a
    # transient reload against a missing or half-written configuration.
    home.activation.materializeDmsHyprlandLua = mkIf dmsEnabled (lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_dir=${lib.escapeShellArg config.xdg.configHome}/hypr
      dms_dir="$config_dir/dms"

      ${pkgs.coreutils}/bin/mkdir -p "$dms_dir"

      atomic_install() {
        src="$1"
        dst="$2"
        tmp="$dst.new.$$"
        ${pkgs.coreutils}/bin/install -m 0644 "$src" "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$dst"
      }

      seed() {
        src="$1"
        dst="$2"
        if [ ! -s "$dst" ]; then
          atomic_install "$src" "$dst"
        fi
      }

      # This was briefly a separately required module. It is now embedded in
      # hyprland.lua so the compositor has no extra runtime lookup dependency.
      ${pkgs.coreutils}/bin/rm -f "$dms_dir/binds-dots.lua"

      seed ${dmsEmbedded}/hypr-binds-user.lua "$dms_dir/binds-user.lua"
      seed ${dmsEmbedded}/hypr-colors.lua "$dms_dir/colors.lua"
      seed ${dmsEmbedded}/hypr-cursor.lua "$dms_dir/cursor.lua"
      seed ${dmsEmbedded}/hypr-layout.lua "$dms_dir/layout.lua"
      seed ${dmsEmbedded}/hypr-outputs.lua "$dms_dir/outputs.lua"
      seed ${dmsEmbedded}/hypr-windowrules.lua "$dms_dir/windowrules.lua"

      # The root Lua requires dms/binds.lua, so install that first and replace
      # hyprland.lua last. Both replacements are same-directory atomic renames.
      atomic_install ${dmsBinds} "$dms_dir/binds.lua"
      atomic_install ${dmsRoot} "$config_dir/hyprland.lua"

      # Home Manager may run inside the live session. If Hyprland's instance
      # environment is available, reload once after the complete tree exists so
      # a stale transient config error is cleared without making activation fail.
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
      fi
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
