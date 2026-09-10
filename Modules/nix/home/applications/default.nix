{
  imports = [
    # Browsers
    ../browser/chromium
    ../browser/zen

    # Editors
    ../editor/helix
    ../editor/nvim
    ../editor/vim
    ../editor/vscode
    ../editor/zeditor

    # Information utilities
    ../info/btop.nix
    ../info/clock.nix
    ../info/fetchers.nix

    # Media
    ../media/editing
    ../media/freetube
    ../media/mpv
    ../media/obs

    # Shells
    ../shells/core/bash
    ../shells/core/fish
    ../shells/core/nushell
    ../shells/core/zsh
    ../shells/prompt/starship.nix

    # Shell tools
    ../shells/tools/atuin.nix
    ../shells/tools/bat.nix
    ../shells/tools/direnv.nix
    ../shells/tools/grep.nix
    ../shells/tools/home-manager.nix
    ../shells/tools/nh.nix
    ../shells/tools/nix-index.nix
    ../shells/tools/topgrade.nix
    ../shells/tools/yazi.nix
  ];
}
