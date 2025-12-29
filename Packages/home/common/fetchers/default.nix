{pkgs, ...}: {
  imports = [
    ./btop.nix
    ./fastfetch.nix
    ./nitch.nix
  ];

  home.packages = with pkgs; [
    neofetch
    nitch
    onefetch
    tokei
    cowsay
  ];
}
