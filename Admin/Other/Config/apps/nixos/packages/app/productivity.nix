{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pdfsam-basic
    rawtherapee
    inkscape-with-extensions
    gimp-with-plugins
    notion-app-enhanced
    anki-bin
    # figma-linux
  ];
}
