{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #> Icons
    breeze-icons
    qogir-icon-theme
    beauty-line-icon-theme

    #> Cursors
    qogir-theme
    tela-icon-theme
    tela-circle-icon-theme
    nordzy-icon-theme
  ];
}
