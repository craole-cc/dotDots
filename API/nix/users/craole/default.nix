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
    settings = {
      alias.project-summary = "!which onefetch && onefetch";
      push.autoSetupRemote = true;
    };
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
    # displayProtocol = "wayland";
    # desktopEnvironment = "cosmic";
    # windowManager = "hyprland";
    # bar = "caelestia";
    # shell = "bash";
    # prompt = "starship";
    keyboard = {
      # modifier = "SUPER";
      swapCapsEscape = false;
      vimKeybinds = false;

      # Scratchpad keys and role modifiers are schema-owned. Scratchpad
      # applications follow the normalized application roles below.

      #~@ Keybindings Map
      #? Define application/action keys agnostic of WM/DE
      # bindings = {
      #   #~@ Quick Launch
      #   launcher = {
      #     # primary = {
      #     # bind="Super";
      #     # command =
      #     # secondary = "Super+Space";
      #     # }
      #   };
      #   terminal = "Meta+Return";
      #   fileManager = "Meta+E";

      #   #~@ Quake/Scratchpad Terminals
      #   quake1 = "Meta+grave"; # Super + `
      #   quake2 = "Meta+Shift+grave"; # Super + ~

      #   #~@ Applications
      #   browser = {
      #     primary = "Meta+B";
      #     secondary = "Meta+Shift+B";
      #   };

      #   editor = {
      #     tty = {
      #       primary = "Meta+C";
      #       secondary = "Meta+Shift+C";
      #     };
      #     gui = {
      #       primary = "Meta+V";
      #       secondary = "Meta+Shift+V";
      #     };
      #   };

      #   #~@ Window Management
      #   closeWindow = "Meta+Q";
      #   fullscreen = "Meta+F";
      #   floating = "Meta+Space";

      #   #~@ Workspace Navigation
      #   workspace = {
      #     next = "Meta+Right";
      #     prev = "Meta+Left";
      #     # Or specific workspaces: "Meta+1" through "Meta+9"
      #   };

      #   #~@ System
      #   lock = "Meta+L";
      #   logout = "Meta+Shift+E";
      #   screenshot = "Print";
      #   screenshotArea = "Meta+Shift+S";

      #   #~@ Audio
      #   volumeUp = "XF86AudioRaiseVolume";
      #   volumeDown = "XF86AudioLowerVolume";
      #   volumeMute = "XF86AudioMute";

      #   #~@ Brightness
      #   brightnessUp = "XF86MonBrightnessUp";
      #   brightnessDown = "XF86MonBrightnessDown";
      # };
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
      dark = "candy-icons";
      light = "candy-icons";
    };
    cursors = {
      accent = "mauve";
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

  applications = {
    browser = {
      primary = "chromium";
      secondary = "zen-twilight";
    };
    editor = {
      tty = {
        primary = "helix";
        secondary = "neovim";
      };
      gui = {
        primary = "vscode";
        secondary = "zed";
        tertiary = "vscode-insiders";
      };
    };
    terminal = {
      # Kitty remains the protocol-neutral schema default. On Wayland Craole
      # promotes Foot, with Ghostty and Kitty as secondary/tertiary roles.
      secondary = "ghostty";
      tertiary = "kitty";
      wayland.primary = "foot";
    };
    explorer = {
      primary = "yazi";
      secondary = "doublecmd";
    };
    launcher = {
      primary = "vicinae";
      secondary = "fuzzel";
    };
    # bar = "caelestia";
    bar = "dank";
    prompt = "starship";

    allowed = [
      # "atuin"
      "fastfetch"
      "freetube"
      "ghostty"
      "kitty"
      "warp-terminal"
      "jujutsu"
      "obs-studio"
      "yazi"
      "vim"
      "vscode" # stable FHS + declarative Insiders are kept as a pair
      # "tmux"
    ];
    utilities = {
      atuin.enable = false;
      bat.enable = true;
      btop.enable = true;
      clock.enable = true;
      direnv.enable = true;
      git.enable = true;
      gitui.enable = true;
      github.enable = true;
      grep.enable = true;
      home-manager.enable = true;
      jujutsu.enable = true;
      nh.enable = true;
      nix-index.enable = true;
      topgrade.enable = true;
      tmux.enable = true;
      yazi.enable = true;
      delta.enable = true;
    };
  };

  paths = rec {
    pics = "home:Pictures";
    dlds = "home:Downloads";
    avatars = {
      session = pics + "/avatar.jpg";
    };
    wallpapers = "home:Pictures/Wallpapers";
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
    #   #   light = wallpapersDir + "/2560x1440/light.jpg";
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
