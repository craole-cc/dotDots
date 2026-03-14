{
  locale,
  fonts,
  mkMerge,
  paths,
  vimKeybinds,
  ...
}: {
  settings = mkMerge [
    (import ./core.nix {inherit fonts;})
    (import ./control.nix {inherit vimKeybinds;})
    (import ./desktop.nix {})
    (import ./info.nix {inherit locale paths;})
  ];
}
