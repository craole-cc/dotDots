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
  variant =
    if cfg.insiders or true
    then "Code - Insiders"
    else "Code";
in
  optionalString ((cfg.enable or false) && (cfg.features.ui.transparency or false)) ''
    sync_vscode_wallpaper() {
      local target wallpaper wallpaper_url tmp
      target=${escapeShellArg "${config.xdg.configHome}/${variant}/User/settings.json"}
      [ -f "$target" ] && [ ! -L "$target" ] || return 0
      wallpaper="$(${bins.dmsCall} wallpaper get 2>/dev/null || true)"
      if [ ! -f "$wallpaper" ]; then
        wallpaper="$(${bins.jaq} -r '.wallpaperPath // empty' ${escapeShellArg "${config.xdg.stateHome}/DankMaterialShell/session.json"} 2>/dev/null || true)"
      fi
      [ -f "$wallpaper" ] || return 0
      wallpaper_url="$(printf '%s' "$wallpaper" | ${bins.jaq} -Rrs '"file://" + (split("/") | map(@uri) | join("/"))')" || return 1
      tmp="$(${bins.mktemp} "$target.tmp.XXXXXX")" || return 1
      if ${bins.jaq} --arg url "$wallpaper_url" --argjson opacity "$editor_opacity" '
        .["custom-ui-style.background.url"] = $url |
        .["custom-ui-style.stylesheet"]["body:has(div[role=application])::before"].opacity = $opacity
      ' "$target" > "$tmp"; then
        ${bins.chmod} --reference="$target" "$tmp"
        if ! ${bins.cmp} -s "$target" "$tmp"; then
          ${bins.mv} -f "$tmp" "$target"
        fi
      fi
      ${bins.rm} -f "$tmp"
    }
    sync_vscode_wallpaper
  ''
