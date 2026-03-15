{lib, ...}: let
  inherit (lib.strings) concatStringsSep;
  toRegex = list: "^(${concatStringsSep "|" list})$";
  common = ["ags" "calendar" "notifications" "osd" "system-menu" "anyrun" "vicinae" "caelestia:launcher"];
  panels = ["bar" "gtk-layer-shell"];
  layers = common ++ panels;
in {
  layerrule = [
    "blur, ${toRegex layers}"
    "xray 1, ${toRegex panels}"
    "ignorealpha 0.2, ${toRegex panels}"
    "ignorealpha 0.5, ${toRegex (common ++ ["music"])}"
  ];

  windowrule = [
    "float, title:^(Media viewer)$"
    "immediate, class:^(osu!|cs2)$"
    "float, title:^(Picture-in-Picture)$"
    "pin, title:^(Picture-in-Picture)$"
    "workspace special silent, title:^(Firefox — Sharing Indicator)$"
    "workspace special silent, title:^(.*is sharing (your screen|a window).)$"
    "workspace 9 silent, title:^(Spotify( Premium)?)$"
    "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
    "idleinhibit focus, class:^(firefox)$, title:^(.*YouTube.*)$"
    "idleinhibit fullscreen, class:^(firefox)$"
    "dimaround, class:^(gcr-prompter)$"
    "dimaround, class:^(xdg-desktop-portal-gtk)$"
    "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
    "noblur, xwayland:1"
    "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
    "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"
  ];
}
