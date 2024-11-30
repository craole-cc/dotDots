{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brave
    whatsapp-for-linux
    warp-terminal
    via
    vscode-fhs
    qbittorrent
    inkscape-with-extensions
    darktable
    ansel
  ];
}
