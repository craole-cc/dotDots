{
  bins,
  config,
  lix,
  pkgs,
  style,
  themes,
  ...
} @ args: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (pkgs) writeShellScript;
  inherit (themes) icons cursors;
  gds = pkgs.gsettings-desktop-schemas;
  syncVSCode = import ./vscode.nix args;
in
  writeShellScript "sync-dms-desktop-appearance" ''
    mode="$(${bins.dmsCall} theme getMode 2>/dev/null || true)"

    case "$mode" in
      dark)
        cursor=${cursors.dark.name}
        cursor_size=${toString cursors.dark.size}
        icons=${icons.dark.name}
        terminal_opacity=${toString style.opacity.terminal.dark}
        editor_opacity=${toString style.opacity.editor.dark}
        btop_theme=adwaita-dark
        foot_signal=USR1
        ;;
      light)
        cursor=${cursors.light.name}
        cursor_size=${toString cursors.light.size}
        icons=${icons.light.name}
        terminal_opacity=${toString style.opacity.terminal.light}
        editor_opacity=${toString style.opacity.editor.light}
        btop_theme=adwaita
        foot_signal=USR2
        ;;
      *) exit 0 ;;
    esac

    xresources="$HOME/.Xresources"
    xresources_writable=false
    if [ -L "$xresources" ]; then
      :
    elif [ -e "$xresources" ] && [ -w "$xresources" ]; then
        xresources_writable=true
    else
      :
    fi

    xresources_needs_update=false
    if [ -f "$xresources" ]; then
      if ${bins.rg} -Fxq "Xcursor.theme: $cursor" "$xresources" &&
        ${bins.rg} -Fxq "Xcursor.size: $cursor_size" "$xresources"; then
        :
      else
        xresources_needs_update=true
      fi
    else
      xresources_needs_update=true
    fi

    if [ "$xresources_writable" = true ] && [ "$xresources_needs_update" = true ]; then
      if tmp="$(${bins.mktemp} "$xresources.tmp.XXXXXX")"; then
        trap '${bins.rm} -f "$tmp"' EXIT
        xresources_filtered=true
        if [ -f "$xresources" ]; then
          if ${bins.jaq} -Rr 'select(test("^[[:space:]]*Xcursor\\.(theme|size):") | not)' \
              "$xresources" > "$tmp"; then
            :
          else
            xresources_filtered=false
          fi
        else
          : > "$tmp"
        fi
        if [ "$xresources_filtered" = true ]; then
          printf 'Xcursor.theme: %s\nXcursor.size: %s\n' "$cursor" "$cursor_size" >> "$tmp"
          if [ -f "$xresources" ]; then
            ${bins.chmod} --reference="$xresources" "$tmp"
          fi
          ${bins.mv} -f "$tmp" "$xresources"
          command -v xrdb >/dev/null 2>&1 && xrdb -merge "$xresources" >/dev/null 2>&1 || true
        fi
        trap - EXIT
        ${bins.rm} -f "$tmp"
      fi
    fi

    export GSETTINGS_SCHEMA_DIR="${gds}/share/gsettings-schemas/${gds.name}/glib-2.0/schemas"
    ${bins.gSetDI} cursor-theme "$cursor" || true
    ${bins.gSetDI} cursor-size "$cursor_size" || true
    ${bins.gSetDI} icon-theme "$icons" || true
    command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor "$cursor" "$cursor_size" >/dev/null 2>&1 || true

    write_opacity_file() {
      local target="$1" setting="$2" tmp
      if [ -L "$target" ]; then
        echo "Refusing to replace managed terminal opacity symlink: $target" >&2
        return 1
      fi
      if [ -f "$target" ] && [ "$(${bins.cat} "$target")" = "$setting" ]; then
        return 1
      fi
      ${bins.mkdir} -p "$(${bins.dirname} "$target")"
      tmp="$(${bins.mktemp} "$target.tmp.XXXXXX")" || return 1
      printf '%s\n' "$setting" > "$tmp"
      ${bins.chmod} 0644 "$tmp"
      ${bins.mv} -f "$tmp" "$target"
    }

    ghostty_opacity=${escapeShellArg themes.ghostty.opacity.path}
    kitty_opacity=${escapeShellArg themes.kitty.opacity.path}
    if write_opacity_file "$ghostty_opacity" "background-opacity = $terminal_opacity"; then
      ${bins.systemctl} --user reload app-com.mitchellh.ghostty.service >/dev/null 2>&1 || true
    fi
    if write_opacity_file "$kitty_opacity" "background_opacity $terminal_opacity"; then
      ${bins.pkill} -USR1 -x kitty || true
    fi

    ${syncVSCode}

    btop_config=${escapeShellArg "${config.xdg.configHome}/btop/btop.conf"}
    if [ -L "$btop_config" ]; then
      echo "Refusing to replace managed btop config symlink: $btop_config" >&2
    else
      ${bins.mkdir} -p "$(${bins.dirname} "$btop_config")"
      if tmp="$(${bins.mktemp} "$btop_config.tmp.XXXXXX")"; then
        if [ -f "$btop_config" ]; then
          if ! ${bins.cat} "$btop_config" |
            ${bins.sd} '^\\s*color_theme\\s*=.*' "color_theme = \"$btop_theme\"" |
            ${bins.sd} '^\\s*theme_background\\s*=.*' 'theme_background = false' > "$tmp"; then
            ${bins.rm} -f "$tmp"
            tmp=
          else
            ${bins.rg} -q '^[[:space:]]*color_theme[[:space:]]*=' "$btop_config" ||
              printf 'color_theme = "%s"\n' "$btop_theme" >> "$tmp"
            ${bins.rg} -q '^[[:space:]]*theme_background[[:space:]]*=' "$btop_config" ||
              printf 'theme_background = false\n' >> "$tmp"
            ${bins.chmod} --reference="$btop_config" "$tmp"
          fi
        else
          printf 'color_theme = "%s"\ntheme_background = false\n' "$btop_theme" > "$tmp"
          ${bins.chmod} 0644 "$tmp"
        fi
        if [ -n "$tmp" ]; then
          if [ ! -f "$btop_config" ] || ! ${bins.cmp} -s "$tmp" "$btop_config"; then
            if ${bins.mv} -f "$tmp" "$btop_config"; then
              ${bins.pkill} -USR2 -x btop || true
            else
              ${bins.rm} -f "$tmp"
            fi
          else
            ${bins.rm} -f "$tmp"
          fi
        fi
      fi
    fi
    ${bins.pkill} -"$foot_signal" -x foot || true
  ''
