{pkgs, ...}: {
  settings = {
    background = {
      desktopClock = {
        enable = false;
      };
      enable = true;
      visualiser = {
        blur = false;
        enabled = false;
        autoHide = true;
        rounding = 1;
        spacing = 1;
      };
    };
  };
}
