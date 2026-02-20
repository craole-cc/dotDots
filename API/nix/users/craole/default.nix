{
  imports = [
    # ./programs
    # ./services
  ];

  description = "Craig 'Craole' Cole";

  password = "$6$2o3rjHVZgXEuyZ97$PtmQa1PIOmKb6dAwZ0mZJUulAkJoCfj.qjJHgtusfVnIIsHmENcA7q8PV9I2PveOwdEdFWwMBgLu3a5HZavXC1";

  git = {
    name = "Craole";
    email = "32288735+Craole@users.noreply.github.com";
  };

  capabilities = [
    "writing" # Document creation, note-taking, content writing
    "conferencing" # Video calls, screen sharing, remote meetings
    "development" # Software development and programming
    "creation" # Creative work (art, music, video production)
    "analysis" # Data analysis, spreadsheets, visualization
    "management" # Project/task management, organization
    "gaming" # Gaming and entertainment
    "multimedia" # Media consumption and light editing
  ];

  shells = [
    "bash"
    "nushell"
    "powershell"
  ];

  interface = {
    displayProtocol = "wayland";
    desktopEnvironment = "cosmic";
    windowManager = "hyprland";
    bar = "caelestia";
    shell = "bash";
    prompt = "starship";
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
      vimKeybinds = false;
      #~@ Keybindings Map
      #? Define application/action keys agnostic of WM/DE
      bindings = {
        #~@ Quick Launch
        launcher = {
          # primary = {
          # bind="Super";
          # command =
          # secondary = "Super+Space";
          # }
        };
        terminal = "Meta+Return";
        fileManager = "Meta+E";

        #~@ Quake/Scratchpad Terminals
        quake1 = "Meta+grave"; # Super + `
        quake2 = "Meta+Shift+grave"; # Super + ~

        #~@ Applications
        browser = {
          primary = "Meta+B";
          secondary = "Meta+Shift+B";
        };

        editor = {
          tty = {
            primary = "Meta+C";
            secondary = "Meta+Shift+C";
          };
          gui = {
            primary = "Meta+V";
            secondary = "Meta+Shift+V";
          };
        };

        #~@ Window Management
        closeWindow = "Meta+Q";
        fullscreen = "Meta+F";
        floating = "Meta+Space";

        #~@ Workspace Navigation
        workspace = {
          next = "Meta+Right";
          prev = "Meta+Left";
          # Or specific workspaces: "Meta+1" through "Meta+9"
        };

        #~@ System
        lock = "Meta+L";
        logout = "Meta+Shift+E";
        screenshot = "Print";
        screenshotArea = "Meta+Shift+S";

        #~@ Audio
        volumeUp = "XF86AudioRaiseVolume";
        volumeDown = "XF86AudioLowerVolume";
        volumeMute = "XF86AudioMute";

        #~@ Brightness
        brightnessUp = "XF86MonBrightnessUp";
        brightnessDown = "XF86MonBrightnessDown";
      };
    };
    style = {
      autoSwitch = true;
      theme = {
        polarity = "dark";
        accent = "teal";
        dark = "Catppuccin Frappé";
        light = "Catppuccin Latte";
      };
      icons = {
        dark = "candy";
        light = "candy";
      };
      cursor = {
        dark = "material";
        light = "material";
      };
      fonts = {
        emoji = "Noto Color Emoji";
        monospace = "Maple Mono NF";
        sans = "Monaspace Radon Frozen";
        serif = "Noto Serif";
        material = "Material Symbols Sharp";
        clock = "Rubik";
      };
    };
  };

  applications = {
    browser = let
      firefox = "zen twilight";
      chromium = "chromium";
    in {
      inherit firefox chromium;
      primary = firefox;
      secondary = chromium;
    };
    editor = {
      tty = {
        primary = "helix";
        secondary = "neovim";
      };
      gui = {
        primary = "vscode";
        secondary = "zeditor";
      };
    };
    terminal = {
      primary = "foot";
      secondary = "ghostty";
    };
    launcher = {
      primary = "vicinae";
      secondary = "fuzzel";
    };
    bar = "caelestia";
    # prompt = "starship";

    allowed = [
      # "atuin"
      "fastfetch"
      "freetube"
      "fresh-editor"
      "warp-terminal"
      "jujutsu"
      "obs-studio"
      "yazi"
      "vim"
    ];
  };

  paths = rec {
    pics = "home:Pictures";
    dlds = "home:Downloads";
    avatars = {
      session = pics + "/avatar.jpg";
    };
    # wallpapers = let
    #   all = [
    #     "dots:Assets/Images/wallpapers"
    #     (pics + "/Wallpapers")
    #   ];
    #   # primary = builtins.head all;
    #   # dark = primary + "/dark.jpg";
    #   # light = primary + "/light.jpg";
    # in {
    #   # inherit all primary dark light;
    #   # Example: Override specific monitor with custom wallpaper
    #   # monitors = {
    #   # "HDMI-A-3" = {
    #   #   dark = wallpapersDir + "/2560x1440/dark/ktc-special.jpg";
    #   #   light = wallpapersDir + "/2560x1440/light/ktc-day.jpg";
    #   # };
    #   #
    #   # Example: Use a directory for random selection
    #   # "DP-3" = {
    #   #   dark = wallpapersDir + "/1600x900/dark/";
    #   #   light = wallpapersDir + "/1600x900/light/";
    #   # };
    # };
  };
}
