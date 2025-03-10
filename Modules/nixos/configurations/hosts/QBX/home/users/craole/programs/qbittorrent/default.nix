{pkgs, ...}: {
  imports = [];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    qbittorrent-enhanced-nox
  ];
}
