{
  configHome,
  stateHome,
  entryAfter,
  toolkit,
  lix,
  style,
  themes,
  user,
  ...
}: let
  inherit (lix.strings.construction) toJSON;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (themes) icons;
  inherit (toolkit.binaries) chmod cmp dirname install0600 install0644 jaq mkdirp mktemp mvf rmf;
  inherit (themes) catppuccin foot ghostty hermes kitty;
in
  entryAfter ["writeBoundary"] ''
    settings=${escapeShellArg "${configHome}/DankMaterialShell/settings.json"}
    session=${escapeShellArg "${stateHome}/DankMaterialShell/session.json"}
    foot_theme=${escapeShellArg foot.path}
    ghostty_opacity=${escapeShellArg ghostty.opacity.path}
    kitty_opacity=${escapeShellArg kitty.opacity.path}

    if [ -n "$DRY_RUN_CMD" ]; then
      echo "Would seed missing DMS settings and terminal appearance files"
    else
      ${mkdirp} "$(${dirname} "$settings")" "$(${dirname} "$session")" \
        "$(${dirname} "$foot_theme")" "$(${dirname} "$ghostty_opacity")" \
        "$(${dirname} "$kitty_opacity")" "$(${dirname} ${escapeShellArg hermes.skinPath})"
      if [ ! -e "$foot_theme" ] && [ ! -L "$foot_theme" ]; then
        ${install0644} ${foot.fallback} "$foot_theme"
      fi
      if [ ! -e "$ghostty_opacity" ] && [ ! -L "$ghostty_opacity" ]; then
        ${install0644} ${ghostty.opacity.fallback} "$ghostty_opacity"
      fi
      if [ ! -e "$kitty_opacity" ] && [ ! -L "$kitty_opacity" ]; then
        ${install0644} ${kitty.opacity.fallback} "$kitty_opacity"
      fi

      # DMS owns its mutable files while running. Seed declarative defaults on
      # first use; activation must preserve the user's saved choices.
      tmp="$(${mktemp})"
      trap '${rmf} "$tmp"' EXIT
      if [ ! -e "$settings" ] && [ ! -L "$settings" ]; then
        ${jaq} -n \
          --arg theme ${escapeShellArg catppuccin.pathStr} \
          --arg darkIcons ${escapeShellArg icons.dark.name} \
          --arg lightIcons ${escapeShellArg icons.light.name} '{
            currentThemeName: "dynamic",
            currentThemeCategory: "dynamic",
            customThemeFile: $theme,
            matugenScheme: "scheme-smart",
            matugenContrast: -0.35,
            screenPreferences: {wallpaper: ["all"]},
            runDmsMatugenTemplates: true,
            matugenTemplateGtk: true,
            matugenTemplateGhostty: ${toJSON ghostty.matugenTemplateEnabled},
            matugenTemplateFoot: ${toJSON foot.matugenTemplateEnabled},
            matugenTemplateVscode: true,
            matugenTemplateZed: true,
            matugenTemplateZenBrowser: true,
            iconThemeDark: $darkIcons,
            iconThemeLight: $lightIcons,
            iconThemePerMode: true
          }' > "$tmp"
        ${install0600} "$tmp" "$settings"
      fi
      if [ -f "$settings" ] && [ ! -L "$settings" ]; then
        settings_tmp="$(${mktemp} "$settings.tmp.XXXXXX")"
        if ${jaq} \
          --arg theme ${escapeShellArg catppuccin.path} \
          --argjson ghosttyTemplate ${toJSON ghostty.matugenTemplateEnabled} \
          --argjson footTemplate ${toJSON foot.matugenTemplateEnabled} \
          ' .customThemeFile = (if .currentThemeName == "dynamic" then $theme else .customThemeFile end) |
            .runDmsMatugenTemplates = (.runDmsMatugenTemplates // true) |
            .matugenTemplateGtk = (.matugenTemplateGtk // true) |
            .matugenTemplateGhostty = (.matugenTemplateGhostty // $ghosttyTemplate) |
            .matugenTemplateFoot = (.matugenTemplateFoot // $footTemplate) ' \
          "$settings" > "$settings_tmp"; then
          if ! ${cmp} -s "$settings_tmp" "$settings"; then
            ${chmod} 0600 "$settings_tmp"
            ${mvf} "$settings_tmp" "$settings"
          else
            ${rmf} "$settings_tmp"
          fi
        else
          ${rmf} "$settings_tmp"
          echo "Could not reconcile DMS settings defaults" >&2
        fi
      fi
      if [ ! -e "$session" ] && [ ! -L "$session" ]; then
        printf '%s\n' ${escapeShellArg (toJSON {
      isLightMode = style.mode == "light";
      themeModeAutoEnabled = user.theme.modes.autoSwitch or false;
    })} > "$tmp"
        ${install0600} "$tmp" "$session"
      fi
      ${rmf} "$tmp"
      trap - EXIT
    fi
  ''
