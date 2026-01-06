{mkMerge}: {
  settings = mkMerge [
    (import ./bar.nix {})
    (import ./services.nix {})
  ];
}
