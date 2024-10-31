{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    # brave
    # nyxt
    polypane
  ];
}
