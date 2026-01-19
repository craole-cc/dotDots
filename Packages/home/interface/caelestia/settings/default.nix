{
  city,
  fonts,
  mkMerge,
  paths,
  keyboard,
  ...
}: {
  settings = mkMerge [
    (import ./core.nix {inherit fonts;})
    (import ./control.nix {inherit keyboard;})
    (import ./desktop.nix {})
    (import ./info.nix {inherit city paths;})
  ];
}
