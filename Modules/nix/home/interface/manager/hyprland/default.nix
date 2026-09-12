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

  # Scratchpad keys/modifiers are normalized by the schema. Application roles
  # come from the same resolved contract used by the session variables, while
  # launch metadata handles app-specific new-window and terminal wrapping.
  scratchpads = user.interface.keyboard.scratchpads or {};
  scratchpadRoles = [
    "primary"
    "secondary"
    "tertiary"
  ];

  scratchpadApps = {
    inherit (apps) terminal browser;
    editor = apps.editor;
    "file-manager" = apps.explorer;
  };

  terminalLaunch = keyboard.bindings.terminal or {};
  windowCycle = keyboard.bindings.windowCycle or {};
  windowLast = keyboard.bindings.windowLast or {};
  primaryTerminal = apps.terminal.primary or null;

  # Keep the three desktop AI clients together in one named special workspace.
  # Launching is handled directly by the Lua binding so the first toggle does
  # not depend on on_created_empty timing or an external shell wrapper.
  aiWorkspace = {
    name = "ai";
    chord = "SUPER + ALT + A";
    commands = [
      "chatgpt"
      "hermes-desktop"
      "claude-desktop"
    ];
  };

  wrapTerminalCommand = entry: command:
    if command == null
    then null
    else if (entry.needsTerminal or false) && builtins.isAttrs primaryTerminal
    then let
      terminalCommand = primaryTerminal.command or null;
      execFlag = primaryTerminal.wrap.execFlag or "-e";
    in
      if terminalCommand == null
      then command
      else "${terminalCommand} ${execFlag} ${command}"
    else command;

  defaultScratchpadCommand = category: role: let
    categoryApps = scratchpadApps.${category} or {};
    entry = categoryApps.${role} or null;
    command =
      if builtins.isAttrs entry
      then entry.launch.scratchpad or entry.command or null
      else null;
  in
    if builtins.isAttrs entry
    then wrapTerminalCommand entry command
    else null;

  scratchpadCommand = category: role: roleConfig: let
    configured = roleConfig.command or null;
  in
    if configured != null
    then configured
    else defaultScratchpadCommand category role;

  mkDmsChordWith = key: binding: extraMods:
    lib.concatStringsSep " + " (
      builtins.filter (part: part != "") (lib.splitString " " (binding.mod or ""))
      ++ extraMods
      ++ [key]
    );

  mkDmsChord = key: binding: mkDmsChordWith key binding [];

  mkDmsScratchpadRoleBind = category: scratchpad: role: let
    key = scratchpad.key or null;
    roleConfig = scratchpad.${role} or {};
    mod = roleConfig.mod or null;
    command = scratchpadCommand category role roleConfig;
  in
    if key == null || mod == null || command == null || command == ""
    then ""
    else let
      chord = mkDmsChord key roleConfig;
      workspace = "${category}-${role}";
    in ''
      hl.workspace_rule({ workspace = ${builtins.toJSON "special:${workspace}"}, on_created_empty = ${builtins.toJSON command} })
      hl.unbind(${builtins.toJSON chord})
      hl.bind(${builtins.toJSON chord}, hl.dsp.workspace.toggle_special(${builtins.toJSON workspace}), { description = ${builtins.toJSON "Toggle ${category} ${role} scratchpad"} })
    '';

  mkDmsScratchpadBinds = category: scratchpad:
    lib.concatStringsSep "" (
      map (role: mkDmsScratchpadRoleBind category scratchpad role) scratchpadRoles
    );

  dmsAiWorkspaceLaunch = lib.concatMapStrings (command: ''
    hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON command}, { workspace = ${builtins.toJSON "special:${aiWorkspace.name} silent"} }))
  '') aiWorkspace.commands;

  dmsAiWorkspaceBind = ''
    hl.unbind(${builtins.toJSON aiWorkspace.chord})
    hl.bind(${builtins.toJSON aiWorkspace.chord}, function()
      local workspace_name = ${builtins.toJSON "special:${aiWorkspace.name}"}
      local workspace = hl.get_workspace(workspace_name)
      local should_launch = workspace == nil

      if workspace ~= nil then
        should_launch = #hl.get_workspace_windows(workspace_name) == 0
      end

      hl.dispatch(hl.dsp.workspace.toggle_special(${builtins.toJSON aiWorkspace.name}))

      if should_launch then
        ${dmsAiWorkspaceLaunch}
      end
    end, { description = "Toggle AI workspace" })
  '';

  dmsTerminalBind = let
    key = terminalLaunch.key or null;
    mod = terminalLaunch.mod or null;
    command =
      if builtins.isAttrs primaryTerminal
      then primaryTerminal.command or null
      else null;
  in
    if key == null || mod == null || command == null || command == ""
    then ""
    else let
      chord = mkDmsChord key terminalLaunch;
    in ''
      hl.unbind(${builtins.toJSON chord})
      hl.bind(${builtins.toJSON chord}, hl.dsp.exec_cmd(${builtins.toJSON command}), { description = "Open primary terminal" })
    '';

  dmsWindowLastBind = let
    key = windowLast.key or null;
    mod = windowLast.mod or null;
  in
    if key == null || mod == null
    then ""
    else let
      chord = mkDmsChord key windowLast;
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
      chord = mkDmsChord key windowCycle;
      reverseChord = mkDmsChordWith key windowCycle ["SHIFT"];
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

      hl.unbind(${builtins.toJSON reverseChord})
      hl.bind(${builtins.toJSON reverseChord}, function()
        dotdots_mru_cycle(-1)
      end, { description = "Cycle recent windows backwards" })

      -- Modifier-only release binds close the current MRU transaction. Keep
      -- them non-consuming so applications still receive the Alt release.
      hl.bind("ALT + ALT_L", dotdots_mru_reset, { release = true, non_consuming = true })
      hl.bind("ALT + ALT_R", dotdots_mru_reset, { release = true, non_consuming = true })
    '';

  dmsDotBinds = pkgs.writeText "dms-hypr-binds-dots.lua" (
    ''
      -- dotDots declarative Hyprland runtime bindings. DMS supplies the
      -- surrounding Lua entrypoint; schema-owned behavior belongs here.
      -- Loaded after DMS's mutable binds-user.lua so explicit dotDots chords
      -- remain authoritative even if DMS has persisted older bindings.
    ''
    + dmsAiWorkspaceBind
    + dmsTerminalBind
    + dmsWindowLastBind
    + dmsWindowCycleBinds
    + lib.concatStringsSep "" (lib.mapAttrsToList mkDmsScratchpadBinds scratchpads)
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
    outputs = payload;
  }
