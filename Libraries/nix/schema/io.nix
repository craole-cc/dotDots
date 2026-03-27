{lib, ...}: let
  inherit (lib.attrsets) isAttrs mapAttrs recursiveUpdate;
  inherit (lib.lists) isList;
  inherit (lib.strings) concatStringsSep;

  __exports = {
    internal = {
      inherit defaults normalizeKeyboard mkKeyboard mkBind;
      keyboardDefaults = defaults.keyboard;
      mkHyprKeybinds = mkBind.hyprland;
    };
    external = {mkKeyboardSchema = mkKeyboard;};
  };

  mod = ["SUPER"];

  defaults.keyboard = {
    modifier = concatStringsSep " " mod;
    swapCapsEscape = true;

    # ── Applications ─────────────────────────────────────────────────────────
    terminal = {
      inherit mod;
      key = "RETURN";
      action = "$TERMINAL";
    };
    terminalSec = {
      mod = mod ++ ["SHIFT"];
      key = "RETURN";
      action = "$TERMINAL_SEC";
    };
    browser = {
      inherit mod;
      key = "B";
      action = "$BROWSER";
    };
    browserSec = {
      mod = mod ++ ["SHIFT"];
      key = "B";
      action = "$BROWSER_SEC";
    };
    visual = {
      inherit mod;
      key = "V";
      action = "$VISUAL";
    };
    visualSec = {
      mod = mod ++ ["SHIFT"];
      key = "V";
      action = "$VISUAL_SEC";
    };
    fileManager = {
      inherit mod;
      key = "E";
      action = "$FILE_MANAGER";
    };
    launcher = {
      inherit mod;
      key = "SUPER_L";
      action = "$LAUNCHER";
    };
    launcherSec = {
      mod = mod ++ ["SHIFT"];
      key = "SPACE";
      action = "$LAUNCHER_SEC";
    };

    # ── Window state ─────────────────────────────────────────────────────────
    #? action = "" means the WM must override — these are WM dispatch commands
    close = {
      inherit mod;
      key = "Q";
      action = "";
    };
    fullscreen = {
      mod = ["ALT"];
      key = "RETURN";
      action = "";
    };
    maximize = {
      mod = mod ++ ["SHIFT"];
      key = "M";
      action = "";
    };
    float = {
      mod = mod ++ ["SHIFT"];
      key = "F";
      action = "";
    };
    pin = {
      mod = mod ++ ["CTRL"];
      key = "F";
      action = "";
    };
    split = {
      inherit mod;
      key = "S";
      action = "";
    };
    pseudo = {
      inherit mod;
      key = "P";
      action = "";
    };
    groupToggle = {
      inherit mod;
      key = "G";
      action = "";
    };
    groupLock = {
      inherit mod;
      key = "T";
      action = "";
    };

    # ── Navigation ───────────────────────────────────────────────────────────
    workspacePrev = {
      inherit mod;
      key = "TAB";
      action = "";
    };
    windowCycle = {
      mod = ["ALT"];
      key = "TAB";
      action = "";
    };

    # ── System ───────────────────────────────────────────────────────────────
    lock = {
      inherit mod;
      key = "L";
      action = "loginctl lock-session";
    };
    logout = {
      mod = mod ++ ["CTRL"];
      key = "L";
      action = "loginctl terminate-session self";
    };
    sleep = {
      mod = mod ++ ["CTRL"];
      key = "S";
      action = "systemctl suspend";
    };
    reboot = {
      mod = mod ++ ["CTRL"];
      key = "R";
      action = "systemctl reboot";
    };
    reboot_soft = {
      mod = mod ++ ["CTRL" "SHIFT"];
      key = "R";
      action = "systemctl soft-reboot";
    };
    shutdown = {
      mod = mod ++ ["CTRL"];
      key = "Q";
      action = "systemctl poweroff";
    };

    # ── Screenshots ──────────────────────────────────────────────────────────
    screenshot = {
      mod = [];
      key = "PRINT";
      action = "";
    };
    screenshotRegion = {
      inherit mod;
      key = "PRINT";
      action = "";
    };
    screenshotWindow = {
      mod = mod ++ ["SHIFT"];
      key = "PRINT";
      action = "";
    };

    # ── Media ────────────────────────────────────────────────────────────────
    mediaPlay = {
      mod = [];
      key = "XF86AudioPlay";
      action = "playerctl play-pause";
    };
    mediaPrev = {
      mod = [];
      key = "XF86AudioPrev";
      action = "playerctl previous";
    };
    mediaNext = {
      mod = [];
      key = "XF86AudioNext";
      action = "playerctl next";
    };

    # ── Audio ────────────────────────────────────────────────────────────────
    volumeUp = {
      mod = [];
      key = "XF86AudioRaiseVolume";
      action = "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+";
    };
    volumeDown = {
      mod = [];
      key = "XF86AudioLowerVolume";
      action = "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-";
    };
    volumeMute = {
      mod = [];
      key = "XF86AudioMute";
      action = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    };
    micMute = {
      mod = [];
      key = "XF86AudioMicMute";
      action = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    };

    # ── Backlight ────────────────────────────────────────────────────────────
    brightnessUp = {
      mod = [];
      key = "XF86MonBrightnessUp";
      action = "brightnessctl set +5%";
    };
    brightnessDown = {
      mod = [];
      key = "XF86MonBrightnessDown";
      action = "brightnessctl set 5%-";
    };
  };

  /**
  Recursively converts all `mod` list fields to space-separated strings.
  Applied at the output boundary so consumers always receive strings.
  */
  normalizeKeyboard = kb:
    mapAttrs (k: v:
      if k == "mod" && isList v
      then concatStringsSep " " v
      else if isAttrs v
      then normalizeKeyboard v
      else v)
    kb;

  mkKeyboard = {
    host,
    user ? {},
  }:
    normalizeKeyboard (
      recursiveUpdate
      (
        recursiveUpdate
        defaults.keyboard
        (host.keyboard or {})
      )
      (user.keyboard or {})
    );

  mkBind = {
    hyprland = kb: "${kb.mod}, ${kb.key}, exec, ${kb.action}";
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
