{ specialArgs, ... }:
let
  enable = specialArgs.host.desktop == "plasma";
in
{
  services =
    if enable then
      {
        desktopManager = {
          plasma6.enable = true;
        };
        displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };
      }
    else
      { };

  security =
    if enable then
      {
        pam.services = {
          login.enableKwallet = true;
          sddm.enableKwallet = true;
        };
      }
    else
      { };
}
