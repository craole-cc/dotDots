{ pkgs, ... }:
{
  imports = [ ];
  home.packages = with pkgs; [
    fastfetch
    jq
    curl
    figlet
    lolcat
  ];
}
