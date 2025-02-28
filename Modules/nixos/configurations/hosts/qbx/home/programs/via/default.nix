{ pkgs, ... }:
{
  imports = [ ];
  home.packages = with pkgs; [
    via
    vial
  ];
}
