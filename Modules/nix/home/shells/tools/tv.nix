{pkgs, ...}: {
  home.packages = with pkgs; [
    nix-search-tv
  ];
}
