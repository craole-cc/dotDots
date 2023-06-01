{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    doublecmd
  ];
}
