{
  dmsEnabled ? false,
  lib,
  mkMerge,
  ...
}: {
  programs = mkMerge [
    (import ./lock.nix {inherit lib;})
    # (import ./panel.nix)
    (import ./shot.nix)
  ];

  services = mkMerge [
    (import ./idle.nix)
    (import ./paper.nix {})
    (lib.mkIf (!dmsEnabled) (import ./polkit.nix))
    # // (import ./shell.nix)
    (import ./sunset.nix)
    # {
    #   mako.enable = true;
    # }
  ];
}
