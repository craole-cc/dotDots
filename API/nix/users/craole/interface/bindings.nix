let
  super = ["SUPER"];
  shift = ["Shift"];
  alt = ["Alt"];
  ctrl = ["Ctrl"];

  left = "Left";
  right = "Right";
  enter = "Return";
  grave = "Grave";
  space = "Space";
  period = "Period";
  comma = "Comma";
  print = "Print";
  pause = "Pause";
  volumeUp = "XF86AudioRaiseVolume";
  volumeDown = "XF86AudioLowerVolume";
  mute = "XF86AudioMute";
  brightnessUp = "XF86MonBrightnessUp";
  brightnessDown = "XF86MonBrightnessDown";

  modifier = super;
  superShift = super ++ shift;
  superCtrl = super ++ ctrl;
  superAlt = super ++ alt;
  superShiftCtrl = super ++ shift ++ ctrl;
  superShiftAlt = super ++ shift ++ alt;
  superCtrlAlt = super ++ ctrl ++ alt;
  superShiftAltCtl = super ++ shift ++ alt ++ ctrl;

  mkBinding = common: overrides:
    common
    // {
      modifier = overrides.modifier or (common.modifier or "");
      category = overrides.category or (common.category or "");
      description = overrides.description or (common.description or "");
      key = overrides.key or (common.key or "");
    };

  #? One binding: "<description>: <label>" on the given modifiers
  mkAction = common: label: modifiers:
    mkBinding common {
      description = "${common.description}: ${label}";
      modifier = modifiers;
    };

  #? Primary (Super), Secondary (Super+Shift) and Tertiary (Super+Alt) variants of one key
  mkTiers = common: [
    (mkAction common "Primary" modifier)
    (mkAction common "Secondary" superShift)
    (mkAction common "Tertiary" superAlt)
  ];
  mkApplication = description: key:
    mkTiers {
      inherit description key modifier;
      category = "application";
    };

  withKey = common: key: common // {inherit key;};

  #? Plain, Shift (incremental) and Super+Alt (exponential) variants of one key
  mkScale = common: key: verb: let
    desc = common.description;
  in [
    (mkBinding common {
      inherit key;
      description = "${desc}: ${verb}";
    })
    (mkBinding common {
      inherit key;
      description = "${desc}: ${verb} incrementally";
      modifier = shift;
    })
    (mkBinding common {
      inherit key;
      description = "${desc}: ${verb} exponentially";
      modifier = superAlt;
    })
  ];
in {
  keyboard = {
    layout = "us";
    variant = "";
    swapCapsEscape = false;
    vimKeybinds = false;
    bindings = {
      #~@ Applications
      launcher = let
        common = {
          description = "Launcher";
          category = "application";
          key = space;
          inherit modifier;
        };
      in [
        (mkBinding common {})
        (mkAction common "Browse clipboard history" superShift)
        (mkAction common "Search files" superAlt)
      ];

      terminalOpen = let
        common = {
          description = "Terminal: Open";
          category = "application";
          key = enter;
          inherit modifier;
        };
      in [
        (mkAction common "Primary" modifier)
        (mkAction common "Secondary" superShift)
      ];

      terminal = mkApplication "Terminal: Scratchpad" grave;

      browser = mkApplication "Browser" "B";
      browserSend =
        mkAction {
          description = "Browser";
          category = "controller";
          key = "B";
        } "Send focused window to primary scratchpad"
        superShiftAlt;
      browserPrivate = let
        common = {
          description = "Browser: Private";
          category = "application";
          key = "B";
        };
      in [
        (mkAction common "Primary" superCtrl)
        (mkAction common "Secondary" superShiftCtrl)
        (mkAction common "Tertiary" superCtrlAlt)
      ];
      explorer = mkApplication "File Manager" "E";
      editor = mkApplication "Code Editor" "C";
      ide = mkApplication "Integrated Development Environment" "V";
      agent = mkApplication "Agent" "A";
      media = mkApplication "Media" "M";

      #~@ System Control
      close = let
        common = {
          description = "Exit";
          category = "controller";
          key = "Q";
          inherit modifier;
        };
      in [
        (mkAction common "Application" superCtrl)
        (mkAction common "Session" superShiftCtrl)
        (mkAction common "System" superCtrlAlt)
      ];

      lock = let
        common = {
          description = "Lock";
          category = "controller";
          key = "L";
          inherit modifier;
        };
      in [
        (mkAction common "Screen" modifier)
        (mkAction common "Session" superCtrl)
        (mkAction common "Application" superAlt)
      ];

      window = let
        common = {
          description = "Window";
          category = "controller";
          key = "F";
          inherit modifier;
        };
      in [
        (mkAction common "Fullscreen" modifier)
        (mkAction common "Maximize/Restore" superShift)
        (mkAction common "Floating" superCtrl)
        (mkAction common "Maximise Column" superAlt)
        (mkAction common "Switch Floating/Tiling Focus" superShiftCtrl)
        (mkAction common "Pin to All Workspaces" superCtrlAlt)
      ];

      workspace = let
        common = {
          description = "Workspace";
          category = "controller";
          inherit modifier;
        };
        mk = key: dir: target: let
          keyed = withKey common key;
        in [
          (mkAction keyed "Move focus ${dir}" modifier)
          (mkAction keyed "Move window ${dir}" superShift)
          (mkAction keyed "Move to ${target} workspace" superAlt)
        ];
      in
        mk right "right" "next" ++ mk left "left" "previous";

      #~@ Capture
      #? Letter keys work on every board; Print (Cidoo) and Pause (RK71) are bare-key shortcuts
      screenshot = let
        common = {
          description = "Screenshot";
          category = "capture";
        };
        letterKey = withKey common "S";
        printKey = withKey common print;
      in [
        (mkAction letterKey "Section" modifier)
        (mkAction letterKey "Screen" superShift)
        (mkAction letterKey "Window" superAlt)
        (mkBinding printKey {description = "Screenshot: Section";})
        (mkAction printKey "Screen" shift)
        (mkAction printKey "Window" alt)
      ];

      record = let
        common = {
          description = "Screen record";
          category = "capture";
        };
        letterKey = withKey common "R";
        pauseKey = withKey common pause;
      in [
        (mkAction letterKey "Section" modifier)
        (mkAction letterKey "Screen" superShift)
        (mkBinding pauseKey {description = "Screen record: Section";})
        (mkAction pauseKey "Screen" shift)
      ];

      #~@ Audio
      volume = let
        description = "Volume";
        category = "audio";
        common = {inherit category description;};
      in
        mkScale common volumeUp "Increase"
        ++ mkScale common volumeDown "Decrease"
        ++ [
          (mkBinding common {
            description = "${description}: Mute or unmute";
            key = mute;
          })
        ];

      #~@ Brightness
      brightness = let
        description = "Brightness";
        category = "display";
        common = {inherit category description;};
      in
        mkScale common brightnessUp "Increase"
        ++ mkScale common brightnessDown "Decrease";

      wallpaper = let
        common = {
          description = "Wallpaper";
          category = "controller";
        };
      in [
        (mkAction (withKey common period) "Next" superShiftAlt)
        (mkAction (withKey common comma) "Previous" superShiftAlt)
        (mkAction (withKey common "W") "Preferences" superCtrl)
        (mkAction (withKey common "W") "Favourite" superAlt)
        (mkAction (withKey common "W") "Delete to Trash" superShiftAltCtl)
        (mkAction (withKey common "W") "Toggle effects" superCtrlAlt)
        (mkAction (withKey common "W") "View snapshot" superCtrl)
        (mkAction (withKey common "S") "View original" superAlt)
        (mkAction (withKey common "S") "View source" superShiftAlt)
      ];
    };
  };
}
