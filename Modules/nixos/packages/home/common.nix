{ pkgs, ... }:
{
  imports = [
    ./bat
    ./helix
  ];
  home.packages = with pkgs; [
    pop
  ];
}
