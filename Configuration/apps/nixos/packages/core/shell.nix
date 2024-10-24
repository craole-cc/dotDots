{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # nushell
    zsh
    # direnv
    zoxide
    zellij
    starship
  ];
}
