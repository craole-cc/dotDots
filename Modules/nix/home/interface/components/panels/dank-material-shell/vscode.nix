{
  config,
  lix,
  bins,
  ...
}: let
  inherit (lix.modules.construction) mkContext;
  inherit (lix.strings.construction) optionalString;
  inherit (lix.strings.transformation) escapeShellArg;
  cfg =
    (mkContext {
      inherit config;
      dom = "editor";
      mod = "vscode";
    }).cfg;
in
  optionalString ((cfg.enable or false) && (cfg.insiders or true) && (cfg.features.ui.transparency or false)) ''
    sync_vscode_wallpaper() {
      local root wallpaper revision tmp
      root=${escapeShellArg "${config.xdg.dataHome}/dotdots/vscode-wallpaper"}
      wallpaper="$(${bins.dmsCall} wallpaper get 2>/dev/null || true)"
      if [ ! -f "$wallpaper" ]; then
        wallpaper="$(${bins.jaq} -r '.wallpaperPath // empty' ${escapeShellArg "${config.xdg.stateHome}/DankMaterialShell/session.json"} 2>/dev/null || true)"
      fi
      [ -f "$wallpaper" ] || return 0
      ${bins.mkdir} -p "$root"
      [ ! -L "$root/wallpaper.jpg" ] && [ ! -L "$root/appearance.json" ] || return 1
      if ! ${bins.cmp} -s "$wallpaper" "$root/wallpaper.jpg"; then
        tmp="$(${bins.mktemp} "$root/.wallpaper.XXXXXX")" || return 1
        if ! ${bins.install} -m 0644 "$wallpaper" "$tmp"; then
          ${bins.rm} -f "$tmp"
          return 1
        fi
        ${bins.mv} -f "$tmp" "$root/wallpaper.jpg"
      fi
      revision="$(${bins.cksum} < "$root/wallpaper.jpg")" || return 1
      tmp="$(${bins.mktemp} "$root/.appearance.XXXXXX")" || return 1
      if ${bins.jaq} -n --arg revision "$revision" --argjson opacity "$editor_opacity" \
        '{revision: $revision, opacity: $opacity}' > "$tmp"; then
        ${bins.chmod} 0644 "$tmp"
        if ! ${bins.cmp} -s "$root/appearance.json" "$tmp"; then
          ${bins.mv} -f "$tmp" "$root/appearance.json"
        fi
      fi
      ${bins.rm} -f "$tmp"
    }
    sync_vscode_wallpaper
  ''
