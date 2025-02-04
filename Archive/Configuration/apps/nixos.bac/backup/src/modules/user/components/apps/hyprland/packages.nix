{ pkgs, ... }:
with pkgs;
[
  #| Notifiers
  dunst
  libnotify
  mako

  eww
  swww

  #| Terminal
  foot
  kitty

  #| Launchers
  anyrun
  fuzzel
  wofi
  walker
  ags

  #| Screenshot Utilities
  grim
  slurp
  wl-clipboard
  hyprshot

  #| Misc
  jq
]
