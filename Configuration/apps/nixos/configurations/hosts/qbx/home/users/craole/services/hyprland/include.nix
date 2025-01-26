{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.env.gnome;
  user = config.dots.env.hyprland.user;
in
{
  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      # package=inputs.hyprland.packages,"${pkgs.system}".hyprland;
    };

    home-manager.users.${user} = {
      wayland.windowManager.hyprland.enable = true;
      imports = [
        #TODO: Use the store path for the user configuration ()
        ./bindings.nix
        ./env.nix
        ./settings.nix
      ];
    };
  };
}
