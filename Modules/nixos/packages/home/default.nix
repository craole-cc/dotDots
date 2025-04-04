{ osConfig, ... }:
{
  home.stateVersion = osConfig.system.stateVersion;
  programs.home-manager.enable = true;
  imports = [
    ./bat
    ./brave
    # ./eww
    ./fastfetch
    ./fd
    # ./firefox
    ./freetube
    # ./fuzzel
    ./ghostty
    ./git
    ./helix
    # ./hyprlock
    # ./hyprshot
    ./jq
    # ./kitty
    ./mpv
    # ./nushell
    # ./powershell
    ./qbittorrent
    ./ripgrep
    ./rofi
    ./starship
    ./swww
    ./thunderbird
    ./via
    ./vscode
    ./warp
    ./waybar
    ./whatsapp
    ./wofi
    ./yt-dlp
    ./zed
  ];
}
