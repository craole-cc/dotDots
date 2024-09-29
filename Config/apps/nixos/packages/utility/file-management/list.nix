{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    exa
    lsd
    du-dust
    fd
    as-tree
    fzf
    ripgrep
  ];
}
