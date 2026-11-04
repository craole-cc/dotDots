{
  dmsEnabled ? false,
  config,
  lix,
  lib,
  mkMerge,
  ...
}: {
  programs = mkMerge [
    (import ./lock.nix {inherit config lix;})
    # (import ./panel.nix)
    (import ./shot.nix)
  ];

  services = mkMerge [
    (lib.mkIf (!dmsEnabled) (import ./idle.nix))
    (import ./paper.nix {})
    (lib.mkIf (!dmsEnabled) (import ./polkit.nix))
    # // (import ./shell.nix)
    (import ./sunset.nix)
    # {
    #   mako.enable = true;
    # }
  ];
}
