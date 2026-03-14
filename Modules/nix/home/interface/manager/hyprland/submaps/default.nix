{mkMerge, ...}: {
  settings.bind = [
    "CTRL ALT, R, submap, resize"
    "CTRL ALT, F, submap, focus"
  ];
  submaps = mkMerge [
    (import ./focus.nix)
    (import ./resize.nix)
  ];
}
