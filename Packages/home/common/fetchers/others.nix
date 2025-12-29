{pkgs, ...}: {
  home.packages = with pkgs; [
    countryfetch
    freshfetch
    gitfetch
    hyfetch
    ipfetch
    macchina
    neofetch
    nitch
    onefetch
    owofetch
    pfetch-rs
    ramfetch
    starfetch
    tokei
    ufetch
  ];
}
