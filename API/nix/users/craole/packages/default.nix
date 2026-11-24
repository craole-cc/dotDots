let
  ai = [
    "pi"
    "chatgpt"
    "claude-desktop"
    "deepseek"
    "hermes-desktop"
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
    (builtins.head ide)
    "helix"
    # "neovim"
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
    "bookworm"
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
