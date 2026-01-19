{keyboard, ...}: let
  inherit (keyboard) vimKeybinds;
in {
  controlCenter = {
    sizes = {
      heightMult = 0.75;
      ratio = 1.75;
    };
  };

  dashboard = {
    enabled = true;
    showOnHover = true;
    mediaUpdateInterval = 500;
    dragThreshold = 50;
    sizes = {
      tabIndicatorHeight = 3;
      tabIndicatorSpacing = 5;
      infoWidth = 200;
      infoIconSize = 25;
      dateTimeWidth = 110;
      mediaWidth = 200;
      mediaProgressSweep = 180;
      mediaProgressThickness = 8;
      resourceProgessThickness = 10;
      weatherWidth = 250;
      mediaCoverArtSize = 150;
      mediaVisualiserSize = 80;
      resourceSize = 200;
    };
  };

  launcher = {
    inherit vimKeybinds;
    enabled = true;
    showOnHover = false;
    maxShown = 7;
    maxWallpapers = 9;
    specialPrefix = "@";
    actionPrefix = ">";
    enableDangerousActions = false;
    dragThreshold = 50;
    hiddenApps = [];
    useFuzzy = {
      apps = true;
      actions = true;
      schemes = true;
      variants = true;
      wallpapers = true;
    };
    sizes = {
      itemWidth = 600;
      itemHeight = 57;
      wallpaperWidth = 280;
      wallpaperHeight = 200;
    };
    actions = [
      {
        command = [
          "autocomplete"
          "calc"
        ];
        name = "Calculator";
        description = "Do simple math equations (powered by Qalc)";
        icon = "calculate";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "autocomplete"
          "scheme"
        ];
        name = "Scheme";
        description = "Change the current colour scheme";
        icon = "palette";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "autocomplete"
          "wallpaper"
        ];
        name = "Wallpaper";
        description = "Change the current wallpaper";
        icon = "image";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "autocomplete"
          "variant"
        ];
        name = "Variant";
        description = "Change the current scheme variant";
        icon = "colors";
        dangerous = false;
        enabled = true;
      }
      {
        command = [
          "autocomplete"
          "transparency"
        ];
        name = "Transparency";
        description = "Change shell transparency";
        icon = "opacity";
        dangerous = false;
        enabled = false;
      }
      {
        command = [
          "caelestia"
          "wallpaper"
          "-r"
        ];
        name = "Random";
        description = "Switch to a random wallpaper";
        icon = "casino";
        dangerous = false;
        enabled = true;
      }
      {
        command = [
          "setMode"
          "light"
        ];
        name = "Light";
        description = "Change the scheme to light mode";
        icon = "light_mode";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "setMode"
          "dark"
        ];
        name = "Dark";
        description = "Change the scheme to dark mode";
        icon = "dark_mode";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "systemctl"
          "poweroff"
        ];
        name = "Shutdown";
        description = "Shutdown the system";
        icon = "power_settings_new";
        enabled = true;
        dangerous = true;
      }
      {
        command = [
          "systemctl"
          "reboot"
        ];
        name = "Reboot";
        description = "Reboot the system";
        icon = "cached";
        enabled = true;
        dangerous = true;
      }
      {
        command = [
          "loginctl"
          "terminate-user"
          ""
        ];
        name = "Logout";
        description = "Log out of the current session";
        icon = "exit_to_app";
        enabled = true;
        dangerous = true;
      }
      {
        command = [
          "loginctl"
          "lock-session"
        ];
        name = "Lock";
        description = "Lock the current session";
        icon = "lock";
        enabled = true;
        dangerous = false;
      }
      {
        command = [
          "systemctl"
          "suspend-then-hibernate"
        ];
        name = "Sleep";
        description = "Suspend then hibernate";
        icon = "bedtime";
        enabled = true;
        dangerous = false;
      }
    ];
  };

  session = {
    inherit vimKeybinds;
    enabled = true;
    dragThreshold = 30;
    commands = {
      logout = [
        "loginctl"
        "terminate-user"
        ""
      ];
      shutdown = [
        "systemctl"
        "poweroff"
      ];
      hibernate = [
        "systemctl"
        "hibernate"
      ];
      reboot = [
        "systemctl"
        "reboot"
      ];
    };
    sizes = {
      button = 80;
    };
  };

  lock = {
    recolourLogo = false;
    enableFprint = true;
    maxFprintTries = 3;
    sizes = {
      heightMult = 0.7;
      ratio = 1.75;
      centerWidth = 600;
    };
  };

  winfo = {
    sizes = {
      heightMult = 0.7;
      detailsWidth = 500;
    };
  };
}
