{pkgs, ...}: {
  programs.mpv.scripts = with pkgs; [mpvScripts.mpris];
  home.packages = with pkgs; [ffmpeg];
}
