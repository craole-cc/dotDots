{pkgs, ...}: {
  workspace = {
    clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
    lookAndFeel = "org.kde.breezedark.desktop";
    cursor = {
      theme = "Bibata-Modern-Ice";
      size = 32;
    };
    iconTheme = "Papirus-Dark";
    wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
  };
}
