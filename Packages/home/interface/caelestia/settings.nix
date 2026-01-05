{pkgs, ...}: {
  settings = {
    background = {
      desktopClock = {
        enable = true;
      };
      enable = true;
      visualiser = {
        enabled = true;
        blur = true;
        autoHide = true;
        rounding = 1;
        spacing = 1;
      };
    };
  };
}
