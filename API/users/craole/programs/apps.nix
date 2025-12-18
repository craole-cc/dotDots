{pkgs, ...}: {
  home.packages = with pkgs; [
    gImageReader
    inkscape
    microsoft-edge
    qbittorrent-enhanced
    warp-terminal
    kdePackages.yakuake
  ];
}
