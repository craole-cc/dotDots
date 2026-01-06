{mkMerge}: {
  settings = mkMerge [
    (import ./bar.nix {})
  ];
}
