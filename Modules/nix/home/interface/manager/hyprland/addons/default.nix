{
  paths,
  mkMerge,
  ...
}: {
  programs = mkMerge [
    (import ./lock.nix)
    # (import ./panel.nix)
    (import ./shot.nix)
  ];

  services = mkMerge [
    (import ./idle.nix)
    (import ./paper.nix {inherit paths;})
    (import ./polkit.nix)
    # // (import ./shell.nix)
    (import ./sunset.nix)
    # {
    #   mako.enable = true;
    # }
  ];

  wayland.windowManager.hyprland.plugins = [];
}
