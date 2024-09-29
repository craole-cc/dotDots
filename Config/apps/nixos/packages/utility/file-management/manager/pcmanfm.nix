{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pcmanfm
    lxmenu-data
    shared-mime-info
  ];
}
