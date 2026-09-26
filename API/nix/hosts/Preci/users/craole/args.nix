{
  description = "Craig 'Craole' Cole";

  hashedPassword = "$6$2o3rjHVZgXEuyZ97$PtmQa1PIOmKb6dAwZ0mZJUulAkJoCfj.qjJHgtusfVnIIsHmENcA7q8PV9I2PveOwdEdFWwMBgLu3a5HZavXC1";

  git = {
    name = "Craole";
    email = "32288735+Craole@users.noreply.github.com";
    settings = {
      alias.project-summary = "!which onefetch && onefetch";
      push.autoSetupRemote = true;
    };
  };

  capabilities = {
    writing = {};
    conferencing = {};
    development = {
      languages.rust = {
        channel = "nightly";
        components = [
          "rust-src"
          "rust-analyzer"
          "rustfmt"
          "clippy"
        ];
      };
    };
    creation = {};
    analysis = {};
    management = {};
    gaming = {};
    multimedia = {};
  };

  packages.shells = [
    "bash"
    "nushell"
    "powershell"
  ];

  interface = {
    keyboard = {
      swapCapsEscape = false;
      vimKeybinds = false;
    };

    themes = {
      autoSwitch = true;
      polarity = "dark";
      dark = {
        flavor = "Catppuccin Frappé";
        accent = "teal";
        icons = "candy-icons";
      };
      light = {
        flavor = "Catppuccin Latte";
        accent = "teal";
        icons = "candy-icons";
      };
    };

    cursors = {
      accent = "mauve";
      dark = "material";
      light = "material";
    };

    fonts = {
      emoji = ["Noto Color Emoji"];
      monospace = ["Maple Mono NF"];
      sans = ["Monaspace Radon Frozen"];
      serif = ["Noto Serif"];
      material = ["Material Symbols Sharp"];
      clock = ["Rubik"];
    };
  };

  applications = {
    ai = {
      primary = "hermes-desktop";
      secondary = "chatgpt";
      tertiary = "claude-desktop";
    };

    browser = {
      primary = "zen-twilight";
      secondary = "chromium";
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
      primary = "foot";
      secondary = "ghostty";
      tertiary = "kitty";
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
      "codex"
      "claude-code"
      "ollama"
      "fastfetch"
      "freetube"
      "ghostty"
      "kitty"
      "warp-terminal"
      "jujutsu"
      "obs-studio"
      "yazi"
      "vim"
      "vscode"
    ];

    utilities = {
      atuin.enable = true;
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
