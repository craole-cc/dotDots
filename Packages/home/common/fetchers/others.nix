{pkgs, ...}: {
  home.packages = with pkgs; [
    neofetch
    nitch
    onefetch
    tokei
    cowsay
  ];
}
