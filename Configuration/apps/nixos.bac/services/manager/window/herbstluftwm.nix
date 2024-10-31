{ pkgs, ... }:

{
  services.xserver.windowManager.herbstluftwm = {
    enable = true;
    configFile = "/home/craole/DOTS/Config/tools/interface/herbstluftwm/.config";
    # configFile = "/home/craole/DOTS/Config/tools/interface/herbstluftwm/modules/autostart.sh";
    # configFile = "../../../../../../Bin/tasks/herbstluftwm.init";
    # configFile = "herbstluftwm.init";
  };
  environment.systemPackages = with pkgs; [
    polybarFull
    picom-next
  ];
}
