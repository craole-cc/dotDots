{ pkgs, ... }:
{
  imports = [ ];
  home.packages = with pkgs; [
    nchat
    whatsapp-for-linux
    whatsie
    zapzap
  ];
}
