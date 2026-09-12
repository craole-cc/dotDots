{
  repo = {
    name = "dots";
    url = "https://github.com/craole-cc/dotDots.git";
    prefix = ".";
    top = "_";
  };

  libraries = {
    collisionStrategy = "warn";
    allowAliases = false;
    allowTests = false;
    name = "lix";
  };

  packages = {
    unstable = true;
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = true;

    core = [
      "nixpkgs"
      "nixpkgs-stable"
      "nixpkgs-unstable"
    ];

    home = [
      "age"
      "caelestia"
      "catppuccin"
      "dank-material-shell"
      "dms-plugin-registry"
      "fresh-editor"
      "helix"
      "hermes-agent"
      "home-manager"
      "llm-agents"
      "noctalia-shell"
      "nvf"
      "plasma"
      "quickshell"
      "treefmt"
      "typix"
      "vscode-insiders"
      "zen-browser"
    ];
  };

  environment = {
    LANG = "en_US.UTF-8";
    TIME = "UTC";

    SHELL = "/bin/bash";
    EDITOR = "hx";
    VISUAL = "code";
    PAGER = "less";
    BROWSER = "zen";
    TERMINAL = "ghostty";

    LOCALHOST = "127.0.0.1";
    NIXPKGS_ALLOW_UNFREE = "1";
  };
}
