{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    jetbrains.idea-community
    jetbrains.jdk
    jdk
  ];
}
