{
  _,
  lib,
  ...
}: let
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) head;
  inherit (_.applications.registry) identify;

  __exports = {
    internal = {
      inherit
        mkFocus
        awesome
        cinnamon
        cosmic
        gnome
        hyprland
        i3
        niri
        openbox
        pantheon
        plasma
        qtile
        river
        sway
        xfce
        xmonad
        ;
    };
    external = {
      appFocus = mkFocus;
      appOnAwesome = awesome;
      appOnCinnamon = cinnamon;
      appOnCosmic = cosmic;
      appOnGnome = gnome;
      appOnHyprland = hyprland;
      appOnI3 = i3;
      appOnNiri = niri;
      appOnOpenbox = openbox;
      appOnPantheon = pantheon;
      appOnPlasma = plasma;
      appOnQtile = qtile;
      appOnRiver = river;
      appOnSway = sway;
      appOnXfce = xfce;
      appOnXmonad = xmonad;
    };
  };

  # ── Desktop Environments ─────────────────────────────────────────────────────

  cinnamon = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  cosmic = app: let
    m = head (identify app);
  in "sh -c 'cosmic-comp-msg focus-window --${m.type} \"${m.value}\" || ${app.exec}'";

  gnome = app: let
    m = head (identify app);
  in "sh -c 'gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval \"global.get_window_actors().find(a => a.meta_window.get_${m.type}() === \\\"${m.value}\\\").meta_window.activate(0)\" || ${app.exec}'";

  plasma = app: let
    m = head (identify app);
  in "sh -c 'qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow $(qdbus org.kde.KWin /KWin org.kde.KWin.getWindowInfo | grep -B5 \"${m.value}\" | grep windowId | awk \"{print \\$2}\") || ${app.exec}'";

  pantheon = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  xfce = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  # ── Window Managers ──────────────────────────────────────────────────────────

  awesome = app: let
    m = head (identify app);
  in "sh -c 'awesome-client \"for c in client.get() do if c.${m.type} == \\\"${m.value}\\\" then c:jump_to() return end end\" || ${app.exec}'";

  bspwm = app: i3 app;

  hyprland = app: let
    candidates = identify app;
    check = concatStringsSep " || " (
      map (
        m: "hyprctl clients | grep -q \"${m.type}: ${m.value}\""
      )
      candidates
    );
    raise = "hyprctl dispatch focuswindow \"${(head candidates).type}:${(head candidates).value}\"";
  in "sh -c 'if ${check}; then ${raise}; else ${app.exec}; fi'";

  i3 = app: let
    m = head (identify app);
  in "sh -c 'i3-msg [${m.type}=\"${m.value}\"] focus || ${app.exec}'";

  niri = app: let
    m = head (identify app);
  in "sh -c 'niri msg action focus-window --match ${m.type}=\"${m.value}\" || ${app.exec}'";

  openbox = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  qtile = app: "sh -c 'qtile cmd-obj -o cmd -f spawn_or_focus -a \"${app.exec}\" || ${app.exec}'";

  river = app:
  # River has no focus-by-class, just launch
    app.exec;

  sway = app: let
    m = head (identify app);
    criterion =
      if m.type == "class"
      then "class"
      else "app_id";
  in "sh -c 'swaymsg [${criterion}=\"${m.value}\"] focus || ${app.exec}'";

  xmonad = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  # ── Dispatch table ───────────────────────────────────────────────────────────
  byEnvironment = {
    inherit
      awesome
      cinnamon
      cosmic
      gnome
      hyprland
      i3
      niri
      openbox
      pantheon
      plasma
      qtile
      river
      sway
      xfce
      xmonad
      bspwm
      ;
  };

  # Resolve the right function for the active environment, fall back to plain exec
  mkFocus = environment: app:
    (byEnvironment.${environment} or (_: app.exec)) app;
in
  __exports.internal // {__rootAliases = __exports.external;}
