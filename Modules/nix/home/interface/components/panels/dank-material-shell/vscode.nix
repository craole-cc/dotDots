# TODO: Update similar to what i did in sync.nix
{
  config,
  lix,
  binaries,
  ...
}: let
  inherit
    (mkContext {
      inherit config;
      dom = "editor";
      mod = "vscode";
    })
    cfg
    ;

  inherit (lix.modules.construction) mkContext;
  inherit (lix.strings.construction) optionalString;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (binaries) chmod0644 cksum cmps dmsCall install0644 jaqna jaqr mkdirp mktemp mvf rmf;
in
  optionalString (
    (cfg.enable or false)
    && (cfg.insiders or true)
    && (cfg.features.ui.transparency or false)
  ) ''
    sync_vscode_wallpaper() {
      local root wallpaper revision tmp
      root=${escapeShellArg "${config.xdg.dataHome}/dotdots/vscode-wallpaper"}
      wallpaper="$(${dmsCall} wallpaper get 2>/dev/null || true)"
      if [ ! -f "$wallpaper" ]; then
        wallpaper="$(${jaqr} '.wallpaperPath // empty' ${escapeShellArg "${config.xdg.stateHome}/DankMaterialShell/session.json"} 2>/dev/null || true)"
      fi
      [ -f "$wallpaper" ] || return 0
      ${mkdirp} "$root"
      [ ! -L "$root/wallpaper.jpg" ] && [ ! -L "$root/appearance.json" ] || return 1
      if ! ${cmps} "$wallpaper" "$root/wallpaper.jpg"; then
        tmp="$(${mktemp} "$root/.wallpaper.XXXXXX")" || return 1
        if ! ${install0644} "$wallpaper" "$tmp"; then
          ${rmf} "$tmp"
          return 1
        fi
        ${mvf} "$tmp" "$root/wallpaper.jpg"
      fi
      revision="$(${cksum} < "$root/wallpaper.jpg")" || return 1
      tmp="$(${mktemp} "$root/.appearance.XXXXXX")" || return 1
      if ${jaqna} revision "$revision" --argjson opacity "$editor_opacity" \
        '{revision: $revision, opacity: $opacity}' > "$tmp"; then
        ${chmod0644} "$tmp"
        if ! ${cmps} "$root/appearance.json" "$tmp"; then
          ${mvf} "$tmp" "$root/appearance.json"
        fi
      fi
      ${rmf} "$tmp"
    }
    sync_vscode_wallpaper
  ''
