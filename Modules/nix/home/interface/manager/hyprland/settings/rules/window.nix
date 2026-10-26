{
  style,
  ...
}: let
  # Window opacity follows the editor opacity from the active theme schema
  # (user.theme.modes.<mode>.opacity.editor) instead of a literal.
  editorOpacity = builtins.toJSON style.opacity.editor.${style.mode};
in {
  windowrule = [
    "float on, match:title ^(Media viewer)$"
    "immediate on, match:class ^(osu!|cs2)$"
    "float on, match:title ^(Picture-in-Picture)$"
    "pin on, match:title ^(Picture-in-Picture)$"
    "workspace special silent, match:title ^(Firefox - Sharing Indicator)$"
    "workspace special silent, match:title ^(.*is sharing (your screen|a window).)$"
    "workspace 9 silent, match:title ^(Spotify( Premium)?)$"
    "opacity 0.97 override 0.97 override, match:class ^(dev.zed.Zed|zed|Zed)$"
    # Compositor-level translucency for VS Code so the editor never has to be
    # patched (patched files make VS Code report a corrupt installation).
    "opacity ${editorOpacity} override ${editorOpacity} override, match:class ^(code-insiders)$"
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
