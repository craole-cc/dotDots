{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
    };
  };
  
  environment.systemPackages = with pkgs; [
    wmctrl
    xclip
    xcolor
    xdo
    xdotool
    xsel
    xtitle
    xwinmosaic
    xorg.xev
    variety
    betterlockscreen
  ];
}
