{pkgs, ...}: {
  plugins = {
    nixMonitor.enable = true;
    systemMonitor.enable = true;
  };

  packages = with pkgs; [dux-gop];
}
