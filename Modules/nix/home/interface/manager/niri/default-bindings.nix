{
  actions,
  lix,
}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.lists.construction) genList;
  bind = title: action: {
    action = actions action [];
    hotkey-overlay.title = title;
  };
  parameterisedBind = title: action: value: {
    action = actions action [value];
    hotkey-overlay.title = title;
  };
  indexed = prefix: suffix: action: title: first: last:
    listToAttrs (map (index: {
      name = "${prefix}${toString index}${suffix}";
      value = {
        action = actions "spawn" ["niri" "msg" "action" action (toString index)];
        hotkey-overlay.title = "${title} ${toString index}";
      };
    }) (genList (offset: first + offset) (last - first + 1)));
in
  {
    "Mod+Shift+Slash" = bind "Show Hotkey Overlay" "show-hotkey-overlay";
    "Mod+O" = bind "Toggle Overview" "toggle-overview";
    "Mod+Comma" = {
      action = actions "spawn" ["dms" "ipc" "settings" "toggle"];
      hotkey-overlay.title = "Toggle Settings";
    };
    "Mod+N" = {
      action = actions "spawn" ["dms" "ipc" "notifications" "toggle"];
      hotkey-overlay.title = "Toggle Notifications";
    };
    "Mod+X" = {
      action = actions "spawn" ["dms" "ipc" "powermenu" "toggle"];
      hotkey-overlay.title = "Toggle Power Menu";
    };

    "Mod+Down" = bind "Focus Window Down" "focus-window-down";
    "Mod+Up" = bind "Focus Window Up" "focus-window-up";
    "Mod+H" = bind "Focus Column Left" "focus-column-left";
    "Mod+J" = bind "Focus Window Down" "focus-window-down";
    "Mod+K" = bind "Focus Window Up" "focus-window-up";
    "Mod+L" = bind "Focus Column Right" "focus-column-right";

    "Mod+Ctrl+Down" = bind "Move Window Down" "move-window-down";
    "Mod+Ctrl+Up" = bind "Move Window Up" "move-window-up";
    "Mod+Ctrl+Left" = bind "Move Column Left" "move-column-left";
    "Mod+Ctrl+Right" = bind "Move Column Right" "move-column-right";
    "Mod+Ctrl+H" = bind "Move Column Left" "move-column-left";
    "Mod+Ctrl+J" = bind "Move Window Down" "move-window-down";
    "Mod+Ctrl+K" = bind "Move Window Up" "move-window-up";
    "Mod+Ctrl+L" = bind "Move Column Right" "move-column-right";
    "Mod+Home" = bind "Focus First Column" "focus-column-first";
    "Mod+End" = bind "Focus Last Column" "focus-column-last";
    "Mod+Ctrl+Home" = bind "Move Column First" "move-column-to-first";
    "Mod+Ctrl+End" = bind "Move Column Last" "move-column-to-last";

    "Mod+Shift+Down" = bind "Focus Monitor Down" "focus-monitor-down";
    "Mod+Shift+Up" = bind "Focus Monitor Up" "focus-monitor-up";
    "Mod+Shift+H" = bind "Focus Monitor Left" "focus-monitor-left";
    "Mod+Shift+J" = bind "Focus Monitor Down" "focus-monitor-down";
    "Mod+Shift+K" = bind "Focus Monitor Up" "focus-monitor-up";
    "Mod+Shift+L" = bind "Focus Monitor Right" "focus-monitor-right";
    "Mod+Shift+Ctrl+Down" = bind "Move Column To Monitor Down" "move-column-to-monitor-down";
    "Mod+Shift+Ctrl+Up" = bind "Move Column To Monitor Up" "move-column-to-monitor-up";
    "Mod+Shift+Ctrl+Left" = bind "Move Column To Monitor Left" "move-column-to-monitor-left";
    "Mod+Shift+Ctrl+Right" = bind "Move Column To Monitor Right" "move-column-to-monitor-right";
    "Mod+Shift+Ctrl+H" = bind "Move Column To Monitor Left" "move-column-to-monitor-left";
    "Mod+Shift+Ctrl+J" = bind "Move Column To Monitor Down" "move-column-to-monitor-down";
    "Mod+Shift+Ctrl+K" = bind "Move Column To Monitor Up" "move-column-to-monitor-up";
    "Mod+Shift+Ctrl+L" = bind "Move Column To Monitor Right" "move-column-to-monitor-right";

    "Mod+Page_Down" = bind "Focus Workspace Down" "focus-workspace-down";
    "Mod+Page_Up" = bind "Focus Workspace Up" "focus-workspace-up";
    "Mod+U" = bind "Focus Workspace Down" "focus-workspace-down";
    "Mod+I" = bind "Focus Workspace Up" "focus-workspace-up";
    "Mod+Ctrl+Page_Down" = bind "Move Column To Workspace Down" "move-column-to-workspace-down";
    "Mod+Ctrl+Page_Up" = bind "Move Column To Workspace Up" "move-column-to-workspace-up";
    "Mod+Ctrl+U" = bind "Move Column To Workspace Down" "move-column-to-workspace-down";
    "Mod+Ctrl+I" = bind "Move Column To Workspace Up" "move-column-to-workspace-up";
    "Mod+Shift+Page_Down" = bind "Move Workspace Down" "move-workspace-down";
    "Mod+Shift+Page_Up" = bind "Move Workspace Up" "move-workspace-up";
    "Mod+Shift+U" = bind "Move Workspace Down" "move-workspace-down";
    "Mod+Shift+I" = bind "Move Workspace Up" "move-workspace-up";

    "Mod+WheelScrollDown" = (bind "Focus Workspace Down" "focus-workspace-down") // {cooldown-ms = 150;};
    "Mod+WheelScrollUp" = (bind "Focus Workspace Up" "focus-workspace-up") // {cooldown-ms = 150;};
    "Mod+Ctrl+WheelScrollDown" = (bind "Move Column To Workspace Down" "move-column-to-workspace-down") // {cooldown-ms = 150;};
    "Mod+Ctrl+WheelScrollUp" = (bind "Move Column To Workspace Up" "move-column-to-workspace-up") // {cooldown-ms = 150;};
    "Mod+WheelScrollRight" = bind "Focus Column Right" "focus-column-right";
    "Mod+WheelScrollLeft" = bind "Focus Column Left" "focus-column-left";
    "Mod+Ctrl+WheelScrollRight" = bind "Move Column Right" "move-column-right";
    "Mod+Ctrl+WheelScrollLeft" = bind "Move Column Left" "move-column-left";
    "Mod+Shift+WheelScrollDown" = bind "Focus Column Right" "focus-column-right";
    "Mod+Shift+WheelScrollUp" = bind "Focus Column Left" "focus-column-left";
    "Mod+Ctrl+Shift+WheelScrollDown" = bind "Move Column Right" "move-column-right";
    "Mod+Ctrl+Shift+WheelScrollUp" = bind "Move Column Left" "move-column-left";

    "Mod+BracketLeft" = bind "Consume Or Expel Window Left" "consume-or-expel-window-left";
    "Mod+BracketRight" = bind "Consume Or Expel Window Right" "consume-or-expel-window-right";
    "Mod+Period" = bind "Expel Window From Column" "expel-window-from-column";
    "Mod+R" = bind "Switch Preset Column Width" "switch-preset-column-width";
    "Mod+Shift+R" = bind "Switch Preset Window Height" "switch-preset-window-height";
    "Mod+Ctrl+R" = bind "Reset Window Height" "reset-window-height";
    "Mod+Ctrl+F" = bind "Expand Column To Available Width" "expand-column-to-available-width";
    "Mod+C" = bind "Center Column" "center-column";
    "Mod+Ctrl+C" = bind "Center Visible Columns" "center-visible-columns";
    "Mod+Minus" = parameterisedBind "Narrow Column" "set-column-width" "-10%";
    "Mod+Equal" = parameterisedBind "Widen Column" "set-column-width" "+10%";
    "Mod+Shift+Minus" = parameterisedBind "Reduce Window Height" "set-window-height" "-10%";
    "Mod+Shift+Equal" = parameterisedBind "Increase Window Height" "set-window-height" "+10%";
    "Mod+Shift+V" = bind "Switch Focus Between Floating And Tiling" "switch-focus-between-floating-and-tiling";

    "Mod+Alt+Q" = {
      action = actions "spawn-sh" ["variety --quotes-next"];
      hotkey-overlay.title = "Wallpaper: Next Quote";
    };
    "Mod+Shift+S" = {
      action = actions "spawn-sh" ["dms screenshot region --no-confirm"];
      hotkey-overlay.title = "Screenshot Region";
    };
    "Ctrl+Print" = {
      action = actions "spawn-sh" ["dms screenshot full"];
      hotkey-overlay.title = "Screenshot Screen";
    };
    "Alt+Print" = {
      action = actions "spawn-sh" ["dms screenshot window"];
      hotkey-overlay.title = "Screenshot Window";
    };
    "Mod+Escape" = (bind "Toggle Keyboard Shortcuts Inhibit" "toggle-keyboard-shortcuts-inhibit") // {allow-inhibiting = false;};
    "Ctrl+Alt+Delete" = bind "Quit Niri" "quit";
    "Mod+Shift+P" = bind "Power Off Monitors" "power-off-monitors";
  }
  // indexed "Mod+" "" "focus-workspace" "Focus Workspace" 1 9
  // indexed "Mod+Ctrl+" "" "move-column-to-workspace" "Move Column To Workspace" 1 9
