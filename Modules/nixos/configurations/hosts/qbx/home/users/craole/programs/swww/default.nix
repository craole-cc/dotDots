{ pkgs, ... }:
{
  imports = [ ];
  home.packages = with pkgs; [
    swww
    imagemagick
    lz4
  ];
}
