{
  kcminputrc = {
    "ButtonRebinds/TabletTool/HUION Huion Tablet_H420X"."329" = "MouseButton,273";
    "ButtonRebinds/TabletTool/HUION Huion Tablet_H420X"."331" = "MouseButton,272";
    "ButtonRebinds/TabletTool/HUION Huion Tablet_H420X"."332" = "MouseButton,273";
    "Libinput/9580/100/HUION Huion Tablet_H420X".OutputUuid = "197399ba-7544-4c10-90db-dc25b0dd0244";
    "Libinput/9580/100/HUION Huion Tablet_H420X".TabletToolRelativeMode = false;
    Mouse.cursorSize = 32;
    Mouse.cursorTheme = "material_light_cursors";
  };

  kdeglobals = {
    General = {
      AccentColor = "70,160,154";
      LastUsedCustomAccentColor = "233,61,88";
      TerminalApplication = "footclient";
      TerminalService = "footclient.desktop";
      XftAntialias = true;
      XftHintStyle = "hintslight";
      XftSubPixel = "rgb";
      accentColorFromWallpaper = true;
      fixed = "Maple Mono Normal NF,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    };

    Icons.Theme = "candy-icons";

    KDE = {
      AutomaticLookAndFeelOnIdle = false;
      DefaultLightLookAndFeel = "org.kde.breezetwilight.desktop";
    };

    "KFileDialog Settings" = {
      "Allow Expansion" = false;
      "Automatically select filename extension" = true;
      "Breadcrumb Navigation" = true;
      "Decoration position" = 2;
      "Show Full Path" = false;
      "Show Inline Previews" = true;
      "Show Preview" = false;
      "Show Speedbar" = true;
      "Show hidden files" = false;
      "Sort by" = "Name";
      "Sort directories first" = true;
      "Sort hidden files last" = false;
      "Sort reversed" = false;
      "Speedbar Width" = 140;
      "View Style" = "DetailTree";
    };

    KScreen.ScreenScaleFactors = "HDMI-A-3=1;HDMI-A-2=1;";

    WM = {
      activeBackground = "48,52,70";
      activeBlend = "198,208,245";
      activeForeground = "198,208,245";
      inactiveBackground = "35,38,52";
      inactiveBlend = "165,173,206";
      inactiveForeground = "165,173,206";
    };
  };

  kiorc = {
    Confirmations.ConfirmDelete = true;
  };

  krunnerrc = {
    Plugins.krunner_keysEnabled = true;
    "Plugins/Favorites".plugins = "krunner_sessions,krunner_powerdevil,krunner_services,krunner_systemsettings";
  };

  ksmserverrc = {
    General.loginMode = "emptySession";
  };

  ksplashrc = {
    KSplash.Theme = "a2n.kuro";
  };

  kwalletrc = {
    Wallet."First Use" = false;
  };
}
