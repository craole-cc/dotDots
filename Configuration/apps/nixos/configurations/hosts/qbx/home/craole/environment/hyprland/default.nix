{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # package=inputs.hyprland.packages,"${pkgs.system}".hyprland;
  };

  home-manager.users.craole = {
    wayland.windowManager.hyprland.enable = true;
    imports = [
      ./bindings.nix
      ./env.nix
      ./settings.nix
    ];
  };
}
