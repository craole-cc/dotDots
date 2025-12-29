{pkgs, ...}: {
  home.packages = with pkgs; [nitch fastfetch onefetch neofetch tokei];
}
