{ pkgs, ... }:

{
  imports = [ ../windowProtocol/X11.nix ];
  services.xserver.windowManager.herbstluftwm = {
    enable = true;
    configFile = "/home/craole/DOTS/Bin/tasks/herbstluftwm.init";
  };
  environment.systemPackages = with pkgs; [
    polybarFull
    picom-next
  ];
}
