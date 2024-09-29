{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    freetube
    shortwave
    netflix
    mpv
    mousai
    songrec
    termusic
  ];
}
