{_, ...}: let
  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.lists.selection) filter;
  inherit (_.lists.predicates) isList;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.options.construction) mkOption mkEnableOption;
  inherit (_.types.primitives) str;
  inherit (_.types.combinators) attrsOf nullOr submodule;

  __exports = {
    internal =
      composites
      // {
        inherit
          defaults
          normalizeKeyboard
          mkKeyboard
          mkKeybindings
          ;
        keyboardDefaults = defaults.keyboard;
        mkHyprKeybindings = mkKeybindings.hyprland;
      };
    external = {
      mkKeyboardSchema = mkKeyboard;
    };
  };

  composites = {
    #~@ Types
    types = rec {
      keybinding = submodule {
        options = {
          action = mkOption {
            type = nullOr str;
            default = null;
          };
          mod = mkOption {
            type = nullOr str;
            default = null;
          };
          key = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      };

      scratchpadRole = submodule {
        options = {
          mod = mkOption {
            type = nullOr str;
            default = null;
          };
          command = mkOption {
            description = "Optional command override for this scratchpad role";
            type = nullOr str;
            default = null;
          };
        };
      };

      scratchpad = submodule {
        options = {
          key = mkOption {
            type = nullOr str;
            default = null;
          };
          primary = mkOption {
            type = scratchpadRole;
            default = {};
          };
          secondary = mkOption {
            type = scratchpadRole;
            default = {};
          };
          tertiary = mkOption {
            type = scratchpadRole;
            default = {};
          };
        };
      };

      keyboard = submodule {
        options = {
          modifier = mkOption {
            type = str;
            default = "";
          };
          swapCapsEscape = mkEnableOption "Swap CapsLock with Escape";
          vimKeybinds = mkEnableOption "Vim-style hjkl navigation bindings";
          bindings = mkOption {
            type = attrsOf keybinding;
            default = {};
          };
          scratchpads = mkOption {
            type = attrsOf scratchpad;
            default = {};
          };
        };
      };
    };
  };

  mod = ["SUPER"];

  # Scratchpad role modifiers are normalized exactly like the rest of the
  # keyboard schema. Categories own only their base key; role selection adds
  # SHIFT/ALT consistently across terminals, editors, browsers, and explorers.
  mkScratchpad = key: {
    inherit key;
    primary.mod = mod;
    secondary.mod = mod ++ ["SHIFT"];
    tertiary.mod = mod ++ ["ALT"];
  };

  defaults = {
    keyboard = {
      modifier = concatStringsSep " " mod;
      swapCapsEscape = true;

      scratchpads = {
        terminal = mkScratchpad "grave";
        editor = mkScratchpad "C";
        browser = mkScratchpad "B";
        media = mkScratchpad "M";
        "file-manager" = mkScratchpad "E";
      };

      bindings = {
        # ── Applications ─────────────────────────────────────────────────────────
        terminal = {
          inherit mod;
          key = "RETURN";
          action = "$TERMINAL";
        };
        terminalSec = {
          mod = mod ++ ["SHIFT"];
          key = "Grave";
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
        code = {
          inherit mod;
          key = "C";
          action = "code";
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
        fileManagerSec = {
          mod = mod ++ ["SHIFT"];
          key = "E";
          action = "$FILE_MANAGER_SEC";
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
        #? action = "" means the WM must override - these are WM dispatch commands
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
        windowLast = {
          mod = [
            "ALT"
            "CTRL"
          ];
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
          mod =
            mod
            ++ [
              "CTRL"
              "SHIFT"
            ];
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
    };
  };

  /**
  Recursively converts all `mod` list fields to space-separated strings.
  Applied at the output boundary so consumers always receive strings.
  */
  normalizeKeyboard = kb:
    mapAttrs (
      k: v:
        if k == "mod" && isList v
        then concatStringsSep " " v
        else if isAttrs v
        then normalizeKeyboard v
        else v
    )
    kb;

  mkKeyboard = {
    host,
    user ? {},
  }:
    normalizeKeyboard (
      recursiveUpdate (recursiveUpdate defaults.keyboard (host.keyboard or {})) (user.keyboard or {})
    );

  mkKeybindings = {
    hyprland = kb:
      map (b: "${b.mod}, ${b.key}, exec, ${b.action}") (
        filter (
          b:
            (b.mod or null) != null
            && (b.key or null) != null
            && (b.action or null) != null
            && (b.action or "") != ""
        ) (attrValues kb.bindings)
      );
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
