{
  binaries,
  config,
  lix,
  pkgs,
  style,
  themes,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.toolkit.write) script;
  inherit (themes) icons cursors;
  inherit (lix.toolkit.binaries // binaries) cat chmod0644 chmodRef cmps dirname dmsCall gSetDI jaqRr mkdirp mktemp mvf pkill pkillUSR1x pkillUSR2x rgFxq rgq rmf sd systemctlUserR;
  gds = pkgs.gsettings-desktop-schemas;
in
  script "sync-dms-desktop-appearance" ''
        mode="$(${dmsCall} theme getMode 2>/dev/null || true)"

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

        # Hyprland owns editor translucency: a window rule is the only way to make
        # the editor transparent without patching it, and the active mode supplies
        # the value. Rewrite the module so light and dark can differ, then reload
        # so already-open windows follow the switch.
        hypr_opacity=${escapeShellArg "${config.xdg.configHome}/hypr/dms/opacity.lua"}
        if [ -d "$(${dirname} "$hypr_opacity")" ]; then
          wanted='-- Managed by dotDots: editor window opacity for the active theme mode.
    hl.window_rule({ match = { class = "^(code-insiders)$" }, opacity = '"$editor_opacity"' })'
          if [ "$(${cat} "$hypr_opacity" 2>/dev/null || true)" != "$wanted" ]; then
            if tmp="$(${mktemp} "$hypr_opacity.tmp.XXXXXX")"; then
              printf '%s\n' "$wanted" > "$tmp"
              ${chmod0644} "$tmp"
              ${mvf} "$tmp" "$hypr_opacity"
              command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
            fi
          fi
        fi

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
          if ${rgFxq} "Xcursor.theme: $cursor" "$xresources" &&
            ${rgFxq} "Xcursor.size: $cursor_size" "$xresources"; then
            :
          else
            xresources_needs_update=true
          fi
        else
          xresources_needs_update=true
        fi

        if [ "$xresources_writable" = true ] && [ "$xresources_needs_update" = true ]; then
          if tmp="$(${mktemp} "$xresources.tmp.XXXXXX")"; then
            trap '${rmf} "$tmp"' EXIT
            xresources_filtered=true
            if [ -f "$xresources" ]; then
              if ${jaqRr} 'select(test("^[[:space:]]*Xcursor\\.(theme|size):") | not)' \
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
                ${chmodRef} "$xresources" "$tmp"
              fi
              ${mvf} "$tmp" "$xresources"
              command -v xrdb >/dev/null 2>&1 && xrdb -merge "$xresources" >/dev/null 2>&1 || true
            fi
            trap - EXIT
            ${rmf} "$tmp"
          fi
        fi

        export GSETTINGS_SCHEMA_DIR="${gds}/share/gsettings-schemas/${gds.name}/glib-2.0/schemas"
        ${gSetDI} cursor-theme "$cursor" || true
        ${gSetDI} cursor-size "$cursor_size" || true
        ${gSetDI} icon-theme "$icons" || true
        command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor "$cursor" "$cursor_size" >/dev/null 2>&1 || true

        write_opacity_file() {
          local target="$1" setting="$2" tmp
          if [ -L "$target" ]; then
            echo "Refusing to replace managed terminal opacity symlink: $target" >&2
            return 1
          fi
          if [ -f "$target" ] && [ "$(${cat} "$target")" = "$setting" ]; then
            return 1
          fi
          ${mkdirp} "$(${dirname} "$target")"
          tmp="$(${mktemp} "$target.tmp.XXXXXX")" || return 1
          printf '%s\n' "$setting" > "$tmp"
          ${chmod0644} "$tmp"
          ${mvf} "$tmp" "$target"
        }

        ghostty_opacity=${escapeShellArg themes.ghostty.opacity.path}
        kitty_opacity=${escapeShellArg themes.kitty.opacity.path}
        if write_opacity_file "$ghostty_opacity" "background-opacity = $terminal_opacity"; then
          ${systemctlUserR} app-com.mitchellh.ghostty.service >/dev/null 2>&1 || true
        fi
        if write_opacity_file "$kitty_opacity" "background_opacity $terminal_opacity"; then
          ${pkillUSR1x} kitty || true
        fi

        btop_config=${escapeShellArg "${config.xdg.configHome}/btop/btop.conf"}
        if [ -L "$btop_config" ]; then
          echo "Refusing to replace managed btop config symlink: $btop_config" >&2
        else
          ${mkdirp} "$(${dirname} "$btop_config")"
          if tmp="$(${mktemp} "$btop_config.tmp.XXXXXX")"; then
            if [ -f "$btop_config" ]; then
              if ! ${cat} "$btop_config" |
                ${sd} '^\\s*color_theme\\s*=.*' "color_theme = \"$btop_theme\"" |
                ${sd} '^\\s*theme_background\\s*=.*' 'theme_background = false' > "$tmp"; then
                ${rmf} "$tmp"
                tmp=
              else
                ${rgq} '^[[:space:]]*color_theme[[:space:]]*=' "$btop_config" ||
                  printf 'color_theme = "%s"\n' "$btop_theme" >> "$tmp"
                ${rgq} '^[[:space:]]*theme_background[[:space:]]*=' "$btop_config" ||
                  printf 'theme_background = false\n' >> "$tmp"
                ${chmodRef} "$btop_config" "$tmp"
              fi
            else
              printf 'color_theme = "%s"\ntheme_background = false\n' "$btop_theme" > "$tmp"
              ${chmod0644} "$tmp"
            fi
            if [ -n "$tmp" ]; then
              if [ ! -f "$btop_config" ] || ! ${cmps} "$tmp" "$btop_config"; then
                if ${mvf} "$tmp" "$btop_config"; then
                  ${pkillUSR2x} btop || true
                else
                  ${rmf} "$tmp"
                fi
              else
                ${rmf} "$tmp"
              fi
            fi
          fi
        fi
        ${pkill} -"$foot_signal" -x foot || true
  ''
