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
    windowManager = "hyprland";
    bar = "noctalia-shell";
    shell = "bash";
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
    prompt = "starship";
  };

  applications = {
    browser = let
      firefox = "palemoon zen twilight";
      chromium = "microsoft edge";
    in {
      inherit firefox chromium;
      primary = firefox;
      secondary = chromium;
      variant = "twilight";
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
      primary = "fuzzel";
      secondary = "wofi";
    };
    bar = "noctalia";
    prompt = "starship";

    allowed = [
      # "atuin"
      "fastfetch"
      "freetube"
      "fresh-editor"
      "warp-terminal"
      "jujutsu"
      "obs-studio"
      "yazi"
    ];
  };

  paths = {
    downloads = "Downloads";
    wallpapers = "Pictures/Wallpapers";
  };
}
