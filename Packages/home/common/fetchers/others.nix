{pkgs, ...}: {
  home.packages = with pkgs; [
    bfetch
    bunnyfetch
    countryfetch
    freshfetch
    ghfetch
    gitfetch
    honeyfetch
    hyfetch
    ipfetch
    macchina
    neofetch
    netfetch
    nitch
    onefetch
    owofetch
    pfetch-rs
    ramfetch
    screenfetch
    starfetch
    tinyfetch
    tokei
    ufetch
  ];
}
