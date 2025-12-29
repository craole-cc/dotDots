{pkgs, ...}: {
  plugins = with pkgs.obs-studio-plugins; [
    wlrobs
  ];
}
