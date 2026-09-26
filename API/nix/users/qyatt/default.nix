{
  password = "$6$2o3rjHVZgXEuyZ97$PtmQa1PIOmKb6dAwZ0mZJUulAkJoCfj.qjJHgtusfVnIIsHmENcA7q8PV9I2PveOwdEdFWwMBgLu3a5HZavXC1";

  git = {
    name = "craole-cc";
    email = "134658831+craole-cc@users.noreply.github.com";
  };

  capabilities = {
    writing = {};
    conferencing = {};
    development = {};
    creation = {};
    analysis = {};
    management = {};
    gaming = {};
    multimedia = {};
  };

  shells = [
    "nushell"
    "bash"
    "powershell"
  ];

  interface = {
    displayProtocol = "wayland";
    desktopEnvironment = "plasma";
    windowManager = "hyprland";
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
    prompt = "posh oh my";
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
        secondary = "neovim";
      };
      gui = {
        visual = "code";
        sudo = "zeditor";
      };
    };
    terminal = {
      primary = "footclient";
      secondary = "ghostty";
    };
    launcher = {
      primary = "rofi";
      secondary = "fuzzel";
    };
  };

  paths = {
    downloads = "Downloads";
  };
}
