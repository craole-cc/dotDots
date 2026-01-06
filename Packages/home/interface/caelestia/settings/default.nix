{
  mkMerge,
  city,
  ...
}: {
  settings = mkMerge [
    (import ./bar.nix {})
    (import ./control.nix {})
    (import ./desktop.nix {})
    (import ./info.nix {inherit city;})
    # (import ./services.nix {})
    # (import ./services.nix {})
    # (import ./services.nix {})
    # (import ./services.nix {})
  ];
}
