{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    home-manager
    curl
    alejandra
    nixfmt
    gnumake
    helix
    bat
    exa
    lsd
  ];
}
