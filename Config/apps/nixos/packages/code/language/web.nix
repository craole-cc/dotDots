{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zola
  ];
}
