{_, ...}: let
  meta = let
    doc = ''
      Focus-or-launch command builders (applications layer).

      For each supported desktop environment and window manager, provides a
      function `app -> string` that produces a shell command which focuses an
      existing window if one is open, or launches the app fresh.

      Usage:
        mkFocus "hyprland" myApp
        # => "sh -c 'if hyprctl clients | grep -q ...; then ...; else ...; fi'"

      Protocol awareness: Wayland compositors (cosmic, hyprland, niri, sway)
      prefer app_id for window matching; Xorg environments prefer class.
      The preferredMatch helper selects automatically from the registry.

      Depends on: applications.registry.
    '';
    functions = {
      inherit byEnvironment mkFocus;
    };
    exports = {
      local = byEnvironment // functions;
      alias = {
        applicationsByEnvironment = byEnvironment;
        mkAppFocus = mkFocus;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.registry) identify;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.construction) concatStringsSep;

  registry = _.applications.registry.default;

  # Protocol list for a named environment entry.
  envProtocol = env: (registry.${env} or {}).protocol or [];

  # Pick the best match type for the environment's protocol.
  # Wayland compositors identify windows by app_id; Xorg by class.
  preferredMatch = env: candidates: let
    preferred =
      if isIn "wayland" (envProtocol env)
      then "app_id"
      else "class";
    match = filter (m: m.type == preferred) candidates;
  in
    if match != []
    then head match
    else head candidates;

  # Shared wmctrl fallback — all Xorg stacking environments use the same call.
  mkWmctrl = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  # ── Wayland compositors ───────────────────────────────────────────────────

  cosmic = app: let
    m = preferredMatch "cosmic" (identify app);
  in "sh -c 'cosmic-comp-msg focus-window --${m.type} \"${m.value}\" || ${app.exec}'";

  hyprland = app: let
    candidates = identify app;
    check = concatStringsSep " || " (
      map (m: "hyprctl clients | grep -q \"${m.type}: ${m.value}\"") candidates
    );
    m = preferredMatch "hyprland" candidates;
  in "sh -c 'if ${check}; then hyprctl dispatch focuswindow \"${m.type}:${m.value}\"; else ${app.exec}; fi'";

  niri = app: let
    m = preferredMatch "niri" (identify app);
  in "sh -c 'niri msg action focus-window --match ${m.type}=\"${m.value}\" || ${app.exec}'";

  sway = app: let
    m = preferredMatch "sway" (identify app);
    criterion =
      if m.type == "class"
      then "class"
      else "app_id";
  in "sh -c 'swaymsg [${criterion}=\"${m.value}\"] focus || ${app.exec}'";

  # River has no focus-by-id protocol — launch only.
  river = app: app.exec;

  # ── Xorg window managers ──────────────────────────────────────────────────

  awesome = app: let
    m = head (identify app);
  in "sh -c 'awesome-client \"for c in client.get() do if c.${m.type} == \\\"${m.value}\\\" then c:jump_to() return end end\" || ${app.exec}'";

  i3 = app: let
    m = head (identify app);
  in "sh -c 'i3-msg [${m.type}=\"${m.value}\"] focus || ${app.exec}'";

  qtile = app: "sh -c 'qtile cmd-obj -o cmd -f spawn_or_focus -a \"${app.exec}\" || ${app.exec}'";

  xmonad = app: let
    m = head (identify app);
  in "sh -c 'wmctrl -a \"${m.value}\" || ${app.exec}'";

  # bspwm uses the same IPC format as i3.
  bspwm = i3;

  # ── Xorg stacking desktop environments (wmctrl) ───────────────────────────

  cinnamon = mkWmctrl;
  openbox = mkWmctrl;
  pantheon = mkWmctrl;
  xfce = mkWmctrl;

  # ── Desktop environments with custom focus APIs ───────────────────────────

  gnome = app: let
    m = head (identify app);
  in "sh -c 'gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval \"global.get_window_actors().find(a => a.meta_window.get_${m.type}() === \\\"${m.value}\\\").meta_window.activate(0)\" || ${app.exec}'";

  plasma = app: let
    m = head (identify app);
  in "sh -c 'qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow $(qdbus org.kde.KWin /KWin org.kde.KWin.getWindowInfo | grep -B5 \"${m.value}\" | grep windowId | awk \"{print \\$2}\") || ${app.exec}'";

  # ── Dispatch ──────────────────────────────────────────────────────────────

  byEnvironment = {
    inherit
      awesome
      bspwm
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

  # Resolve the focus-or-launch command for `environment`, falling back to
  # plain exec when the environment has no registered handler.
  mkFocus = environment: app: (byEnvironment.${environment} or (_: app.exec)) app;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
