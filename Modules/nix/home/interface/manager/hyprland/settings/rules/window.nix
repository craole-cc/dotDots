{
  windowrule = [
    "float on, match:title ^(Media viewer)$"
    "immediate on, match:class ^(osu!|cs2)$"
    "float on, match:title ^(Picture-in-Picture)$"
    "pin on, match:title ^(Picture-in-Picture)$"
    "workspace special silent, match:title ^(Firefox — Sharing Indicator)$"
    "workspace special silent, match:title ^(.*is sharing (your screen|a window).)$"
    "workspace 9 silent, match:title ^(Spotify( Premium)?)$"
    "idle_inhibit focus, match:class ^(mpv|.+exe|celluloid)$"
    "idle_inhibit focus, match:class ^(firefox)$, match:title ^(.*YouTube.*)$"
    "idle_inhibit fullscreen, match:class ^(firefox)$"
    "dim_around on, match:class ^(gcr-prompter)$"
    "dim_around on, match:class ^(xdg-desktop-portal-gtk)$"
    "dim_around on, match:class ^(polkit-gnome-authentication-agent-1)$"
    "no_blur on, match:xwayland 1"
    "center on, match:class ^(.*jetbrains.*)$, match:title ^(Confirm Exit|Open Project|win424|win201|splash)$"
    "size 640 400, match:class ^(.*jetbrains.*)$, match:title ^(splash)$"
  ];
}
