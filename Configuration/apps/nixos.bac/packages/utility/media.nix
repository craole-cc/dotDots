{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    playerctl
    curseradio
    pamixer
    # sound-theme-freedesktop
  ];
}
