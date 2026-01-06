{mkMerge}: {
  settings = mkMerge [
    (import ./bar.nix {})
    (import ./services.nix {})
    (import ./control.nix {})
    (import ./desktop.nix {})
    # (import ./services.nix {})
    # (import ./services.nix {})
    # (import ./services.nix {})
    # (import ./services.nix {})
  ];
}
