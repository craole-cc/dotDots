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
    desktopEnvironment = "plasma";
    windowManager = "niri";
    bar = "noctalia-shell";
    shell = "bash"; #TODO: This should be the first in the shells list
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
    prompt = "starship";
  };

  applications = {
    browser = let
      firefox = "zen";
      chromium = "edge";
    in {
      inherit firefox chromium;
      primary = firefox;
      secondary = chromium;
    };
    editor = {
      tty = {
        primary = "helix";
        secondary = "fresh";
      };
      gui = {
        primary = "vscode";
        secondary = "zed";
      };
    };
    terminal = {
      primary = "foot";
      secondary = "warp-terminal";
    };
    launcher = {
      primary = "fuzzel";
      secondary = "wofi";
    };
    bar = {
      primary = "noctalia";
      secondary = null;
    };

    allowed = [
      # "atuin"
      # "bash"
      # "bat"
      # "fastfetch"
      # "foot"
      # "freetube"
      # "ghostty"
      # "git"
      # "helix"
      # "jujutsu"
      # "nushell"
      # "obs-studio"
      # "powershell"
      # "quickshell"
      # "starship"
      # "vscode"
      # "yazi"
      # "zed-editor"
      # "zen-browser"
    ];
  };

  paths = {
    downloads = "Downloads";
  };
}
