{ specialArgs, ... }:
let
  enable = specialArgs.host.desktop == "hyprland";
in
{
  services =
    if enable then
      {
        hypridle = {
          enable = true;
        };
      }
    else
      { };
}
