{
  inputs,
  outputs,
  ...
}: {
  imports = [
    ../global
    ../tools/desktop/hyprland
    ../tools/desktop/wireless
    ../tools/productivity
    ../tools/pass
    ../tools/games
  ];

  wallpaper = outputs.wallpapers.aenami-lunar;
  colorscheme = inputs.nix-colors.colorSchemes.atelier-heath;

  monitors = [
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      workspace = "1";
    }
  ];
}
