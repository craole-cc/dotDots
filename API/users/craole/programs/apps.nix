{pkgs, ...}: {
  home.packages = with pkgs; [
    gImageReader
    inkscape
    microsoft-edge
    qbittorrent-enhanced
    warp-terminal
    kdePackages.yakuake
    swaybg
    cachix
  ];

  programs = {
    alacritty.enable = true; # Super+T in the default setting (terminal)
    fuzzel.enable = true; # Super+D in the default setting (app launcher)
    swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
    waybar.enable = true; # launch on startup in the default setting (bar)
  };
  services = {
    mako.enable = true; # notification daemon
    swayidle.enable = true; # idle management daemon
    # polkit-gnome.enable = true; # polkit
  };
}
