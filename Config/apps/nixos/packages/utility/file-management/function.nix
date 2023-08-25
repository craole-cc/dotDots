{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    trashy
    file
    bat
  ];
}
