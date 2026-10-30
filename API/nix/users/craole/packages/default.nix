let
  ai = [
    "hermes-desktop"
    "chatgpt"
    "claude-desktop"
    "claude-code"
    "codex"
    "ollama"
  ];

  panel = [
    "dms"
    # "caelestia"
  ];

  browser = [
    "chromium"
    "zen-twilight"
    "thunderbird"
    "brave"
  ];

  editor = [
    "helix"
    "neovim"
    (builtins.head ide)
  ];

  ide = [
    "vscode-fhs"
    "zed-editor-fhs"
    "vscode-insiders"
  ];

  explorer = [
    "yazi"
    "nemo"
    "thunar"
    "doublecmd"
  ];

  shell = [
    "bash"
    "nushell"
    "powershell"
    "zsh"
  ];

  coding = [
    "common"
    "github"
    "markup"
    "nix"
    "python"
    "rust"
    "shellscript"
    "typos"
    "typst"
    "zig"
  ];

  extra = [
    "fastfetch"
    "imv"
    # "obs-studio"
    "qimgv"
    "qbittorrent-enhanced"
  ];

  media = [
    "kew"
    "freetube"
    "shortwave"
    "celluloid"
    "mpv"
    "cmus"
    "playerctl"
    # "lollypop"
  ];

  launcher = [
    "vicinae"
  ];

  prompt = [
    "starship"
  ];

  terminal = [
    "ghostty"
    "foot"
    "warp-terminal"
    "kitty"
  ];

  wallpaper = [
    "variety"
  ];
in {
  packages = {
    ai-agent = ai;
    bar = panel;
    inherit ai browser coding editor explorer extra ide launcher media panel prompt shell terminal wallpaper;
  };
}
