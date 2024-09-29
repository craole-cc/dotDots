{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    feh
    flameshot
    imagemagick
    # geeqie
    # viu
  ];
}
