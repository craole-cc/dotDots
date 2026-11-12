let
  ai = [
    "hermes-desktop"
    "chatgpt"
    "claude-desktop"
    "claude-code"
    "codex"
    "ollama"
    "continue"
    "llmhop"
  ];

  panel = [
    "dms"
    # "caelestia"
  ];

  browser = [
    "chromium"
    "zen-twilight"
    "thunderbird"
  ];

  editor = [
    "helix"
    # "neovim"
    # (builtins.head ide)
  ];

  ide = [
    "vscode-fhs"
    "zed-editor-fhs"
    "vscode-insiders"
  ];

  explorer = [
    "dux-files"
    "yazi"
    "doublecmd"
  ];

  shell = [
    "bash"
    "powershell"
    # "nushell" # TODO: Disabled until its development packages build reliably.
    # "fish"
    # "zsh"
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

  media = [
    "kew"
    "freetube"
    "shortwave"
    "celluloid"
    "mpv"
    "cmus"
    "playerctl"
  ];

  launcher = [
    "vicinae"
  ];

  prompt = [
    "starship"
  ];

  terminal = [
    "kitty"
    "ghostty"
    "foot"
    # "warp-terminal"
  ];

  wallpaper = [
    "variety"
  ];

  extra = [
    "fromStable.onlyoffice-desktopeditors"
    "fastfetch"
    "imv"
    "inkscape"
    # "obs-studio"
    "qimgv"
    "qbittorrent-enhanced"
    "via"
    "vial"
  ];
in {
  packages = {
    ai-agent = ai;
    bar = panel;
    inherit
      ai
      browser
      coding
      editor
      explorer
      extra
      ide
      launcher
      media
      panel
      prompt
      shell
      terminal
      wallpaper
      ;
  };
}
