{
  config,
  host,
  lib,
  lix,
  pkgs,
  user,
  apps,
  keyboard,
  style,
  ...
}: let
  legacyApps = apps.legacy;
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
  inherit (lix.lists.access) head;
  inherit (lix.lists.construction) toList;
  inherit (lix.lists.selection) filter;
  inherit (lix.strings.construction) concatStringsSep splitString toJSON;

  dmsEnabled = config.programs.dank-material-shell.enable or false;
  dmsEmbedded = "${pkgs.dms-shell.src}/core/internal/config/embedded";

  firstBinding = name: let
    bindings = toList (keyboard.bindings.${name} or []);
  in
    if bindings == []
    then {}
    else head bindings;
  windowCycle = firstBinding "windowCycle";
  windowCycleReverse = firstBinding "windowCycleReverse";
  windowLast = firstBinding "windowLast";
  mkDmsChord = binding: concatStringsSep " + " ((filter (part: part != "") (splitString " " binding.mod)) ++ [binding.key]);

  applicationBinds = import ./applications.nix {
    inherit apps lix;
    inherit (keyboard) scratchpads;
  };
  keyboardBinds = import ./bindings.nix {
    inherit keyboard lix;
    ghosttyEnabled = config.programs.ghostty.enable or false;
  };

  dmsKittyWindowRule = ''
    -- Kitty sometimes requests maximisation when opened inside a special
    -- workspace. Keep new windows in the workspace's tiled layout.
    hl.window_rule({ match = { class = "^kitty$" }, suppress_event = "maximize" })
  '';

  dmsWindowLastBind = let
    key = windowLast.key or null;
    mod = windowLast.mod or null;
  in
    if key == null || mod == null
    then ""
    else let
      chord = mkDmsChord windowLast;
    in ''
      hl.unbind(${builtins.toJSON chord})
      hl.bind(${builtins.toJSON chord}, hl.dsp.focus({ last = true }), { description = "Focus previous window" })
    '';

  dmsWindowCycleBinds = let
    key = windowCycle.key or null;
    mod = windowCycle.mod or null;
  in
    if key == null || mod == null
    then ""
    else let
      chord = mkDmsChord windowCycle;
      reverseBind =
        if (windowCycleReverse.key or null) == null || (windowCycleReverse.mod or null) == null
        then ""
        else ''
          hl.unbind(${toJSON (mkDmsChord windowCycleReverse)})
          hl.bind(${toJSON (mkDmsChord windowCycleReverse)}, function()
            dotdots_mru_cycle(-1)
          end, { description = "Cycle recent windows backwards" })
        '';
      releaseBinds = concatStringsSep "" (map (
        binding:
          if (binding.key or null) == null || (binding.mod or null) == null
          then ""
          else ''
            hl.bind(${toJSON (mkDmsChord binding)}, dotdots_mru_reset, { release = ${toJSON (binding.release or false)}, non_consuming = ${toJSON (binding.nonConsuming or false)} })
          ''
      ) (toList (keyboard.bindings.windowCycleRelease or [])));
    in ''
      -- Global MRU window switching. Hyprland exposes its compositor-wide focus
      -- history directly to Lua, so keep the cycle in-process rather than
      -- spawning hyprctl/jq on every Tab press. Regular and special workspaces
      -- are both valid application locations and participate in the same MRU.
      local dotdots_mru = { windows = nil, index = 0 }

      local function dotdots_mru_reset()
        dotdots_mru.windows = nil
        dotdots_mru.index = 0
      end

      local function dotdots_mru_snapshot()
        local windows = {}
        local active = hl.get_active_window()
        local active_address = active and active.address or nil

        for _, window in ipairs(hl.get_windows()) do
          local workspace = window.workspace
          if window.mapped
            and window.focus_history_id >= 0
            and workspace ~= nil
          then
            table.insert(windows, {
              address = window.address,
              focus_history_id = window.focus_history_id,
            })
          end
        end

        table.sort(windows, function(a, b)
          return a.focus_history_id < b.focus_history_id
        end)

        local active_index = 0
        for index, window in ipairs(windows) do
          if window.address == active_address then
            active_index = index
            break
          end
        end

        return windows, active_index
      end

      local function dotdots_mru_cycle(step)
        if dotdots_mru.windows == nil then
          dotdots_mru.windows, dotdots_mru.index = dotdots_mru_snapshot()
        end

        local count = #dotdots_mru.windows
        if count == 0 then
          return
        end

        local attempts = 0
        repeat
          if dotdots_mru.index == 0 then
            dotdots_mru.index = step > 0 and 1 or count
          else
            dotdots_mru.index = ((dotdots_mru.index - 1 + step) % count) + 1
          end

          local target = dotdots_mru.windows[dotdots_mru.index]
          if target ~= nil and hl.get_window("address:" .. target.address) ~= nil then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
            return
          end

          attempts = attempts + 1
        until attempts >= count
      end

      hl.unbind(${builtins.toJSON chord})
      hl.bind(${builtins.toJSON chord}, function()
        dotdots_mru_cycle(1)
      end, { description = "Cycle recent windows" })

      ${reverseBind}
      ${releaseBinds}
    '';

  dmsDotBinds = pkgs.writeText "dms-hypr-binds-dots.lua" (
    ''
      -- dotDots declarative Hyprland runtime bindings. DMS supplies the
      -- surrounding Lua entrypoint; schema-owned behavior belongs here.
      -- Loaded after DMS's mutable binds-user.lua so explicit dotDots chords
      -- remain authoritative even if DMS has persisted older bindings.
    ''
    + dmsKittyWindowRule
    + keyboardBinds
    + dmsWindowLastBind
    + dmsWindowCycleBinds
    + applicationBinds
  );

  dmsRoot = pkgs.runCommand "dms-hyprland.lua" {} ''
    ${pkgs.gnused}/bin/sed \
      '/-- DMS_STARTUP_BEGIN/,/-- DMS_STARTUP_END/d' \
      ${dmsEmbedded}/hyprland.lua \
      | ${pkgs.gawk}/bin/awk -v binds=${lib.escapeShellArg dmsDotBinds} '
          { print }
          /require\("dms.binds-user"\)/ {
            while ((getline line < binds) > 0) print line
            close(binds)
          }
        ' > "$out"
  '';
  dmsBinds = pkgs.runCommand "dms-hypr-binds.lua" {} ''
    substitute \
      ${dmsEmbedded}/hypr-binds.lua \
      "$out" \
      --replace-fail \
        '{{TERMINAL_COMMAND}}' \
        ${lib.escapeShellArg legacyApps.terminal.primary.command}
  '';

  mkAddons = target:
    mkIf cfg.withAddons
    (import ./addons {
      inherit config lib lix mkMerge dmsEnabled;
    }).${
      target
    };

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
          style
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

    # The portal identifies native apps by their app-named systemd unit. Start
    # Ghostty through its packaged service so global keybind registration has
    # the required application ID, even before any terminal window opens.
    xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service" = mkIf (dmsEnabled && (config.programs.ghostty.enable or false)) {
      source = "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";
    };

    programs = mkAddons "programs";
    services = mkAddons "services";

    # DMS's compositor setup is intentionally not part of the runtime workflow.
    # Materialise all dependencies before atomically replacing the active Lua
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

      # `nixos-rebuild switch` does not reliably preserve the live compositor's
      # HYPRLAND_INSTANCE_SIGNATURE in Home Manager's activation environment.
      # hyprctl can select an instance by index, so reload every live instance
      # owned by this user and stop at the first nonexistent index.
      if command -v hyprctl >/dev/null 2>&1; then
        instance=0
        while hyprctl -i "$instance" reload >/dev/null 2>&1; do
          instance=$((instance + 1))
        done
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
    outputs = mkMerge [
      payload
      (import ./wayvnc.nix {inherit host lib pkgs user;})
    ];
  }
