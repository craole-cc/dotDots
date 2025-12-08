{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    catppuccin-gtk
    catppuccin-kvantum
    papirus-icon-theme
    catppuccin-papirus-folders
    tinty
    figlet
    cowsay
    lolcat
  ];

  programs.dconf.enable = true;
}
