{ pkgs, ... }:
{
  imports = [ ];
  home.packages = with pkgs; [ warp-terminal ];
}
