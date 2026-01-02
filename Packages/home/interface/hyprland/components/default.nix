{mkMerge}: {
  programs = mkMerge [
    (import ./lock.nix)
    (import ./panel.nix)
    (import ./shot.nix)
  ];

  services = mkMerge [
    (import ./idle.nix)
    (import ./paper.nix)
    (import ./polkit.nix)
    # // (import ./shell.nix)
    (import ./sunset.nix)
  ];
}
