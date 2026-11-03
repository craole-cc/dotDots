{
  configHome,
  dms,
  stateHome,
  entryAfter,
  lix,
  style,
  themes,
  user,
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (themes) icons;
  inherit (lix.toolkit.write) json;
  inherit (lix.toolkit.binaries) chmod0600 cmps dirname install0644 jaq jaqn mkdirp mktemp mvf readlinkf rmf;
  inherit (themes) catppuccin foot ghostty hermes kitty;

  defaults = import ./defaults {inherit lix;};
  toOutput = import ./settings-output.nix {inherit lix;};
  settingsOutput = toOutput (dms.settings or {});
  defaultsOutput = toOutput defaults.settings;
  settingsOverrides = settingsOutput.settings;
  settingsDefaults = recursiveUpdate defaultsOutput.settings {
    currentThemeName = "dynamic";
    currentThemeCategory = "dynamic";
    customThemeFile = catppuccin.path;
    matugenScheme = "scheme-smart";
    matugenContrast = -0.35;
    screenPreferences.wallpaper = ["all"];
    runDmsMatugenTemplates = true;
    matugenTemplateGtk = true;
    matugenTemplateGhostty = ghostty.matugenTemplateEnabled;
    matugenTemplateFoot = foot.matugenTemplateEnabled;
    matugenTemplateVscode = true;
    matugenTemplateZed = true;
    matugenTemplateZenBrowser = true;
    iconThemeDark = icons.dark.theme;
    iconThemeLight = icons.light.theme;
    iconThemePerMode = true;
  };
  sessionDefaults = recursiveUpdate defaults.session {
    isLightMode = style.mode == "light";
    themeModeAutoEnabled = user.theme.modes.autoSwitch or false;
  };

  settingsOverridesFile = json "dms-settings-overrides.json" settingsOverrides;
  settingsDefaultsFile = json "dms-settings-defaults.json" settingsDefaults;
  pluginOverridesFile = json "dms-plugin-settings-overrides.json" (dms.plugins or {});
  clipboardOverridesFile = json "dms-clipboard-settings-overrides.json" settingsOutput.clipboardSettings;
  sessionOverridesFile = json "dms-session-overrides.json" (dms.session or {});
  pluginDefaultsFile = json "dms-plugin-settings-defaults.json" defaults.plugins;
  clipboardDefaultsFile = json "dms-clipboard-settings-defaults.json" defaultsOutput.clipboardSettings;
  sessionDefaultsFile = json "dms-session-defaults.json" sessionDefaults;

  mergeJson = target: overrides: defaults: create: ''
    merge_json "$${target}" ${escapeShellArgs [
      overrides
      defaults
      (
        if create
        then "true"
        else "false"
      )
    ]}
  '';
in
  entryAfter ["writeBoundary"] ''
    settings=${escapeShellArg "${configHome}/dms/settings.json"}
    plugins=${escapeShellArg "${configHome}/dms/plugin_settings.json"}
    clipboard=${escapeShellArg "${configHome}/dms/clsettings.json"}
    session=${escapeShellArg "${stateHome}/dms/session.json"}
    foot_theme=${escapeShellArg foot.path}
    ghostty_opacity=${escapeShellArg ghostty.opacity.path}
    kitty_opacity=${escapeShellArg kitty.opacity.path}

    if [ -n "$DRY_RUN_CMD" ]; then
      echo "Would reconcile declared DMS settings and seed missing appearance files"
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

      merge_json() {
        local target="$1" overrides="$2" defaults="$3" create="$4" target_tmp
        if [ ! -e "$target" ] && [ ! -L "$target" ] && [ "$create" != "true" ]; then
          return 0
        fi
        if [ -L "$target" ]; then
          case "$(${readlinkf} "$target")" in
            /nix/store/*) ;;
            *) echo "Refusing to replace unmanaged DMS settings symlink: $target" >&2; return 1 ;;
          esac
        fi
        target_tmp="$(${mktemp} "$target.tmp.XXXXXX")" || return 1
        if [ -f "$target" ]; then
          if ! ${jaq} --slurpfile overrides "$overrides" --slurpfile defaults "$defaults" \
            '($defaults[0] * . * $overrides[0]) | if .currentThemeName == "dynamic" and ($overrides[0] | has("customThemeFile") | not) then .customThemeFile = $defaults[0].customThemeFile else . end' \
            "$target" > "$target_tmp"; then
            ${rmf} "$target_tmp"
            return 1
          fi
        else
          if ! ${jaqn} --slurpfile overrides "$overrides" --slurpfile defaults "$defaults" \
            '($defaults[0] * $overrides[0]) | if .currentThemeName == "dynamic" and ($overrides[0] | has("customThemeFile") | not) then .customThemeFile = $defaults[0].customThemeFile else . end' \
            > "$target_tmp"; then
            ${rmf} "$target_tmp"
            return 1
          fi
        fi
        if ! ${cmps} "$target_tmp" "$target"; then
          ${chmod0600} "$target_tmp"
          ${mvf} "$target_tmp" "$target"
        else
          ${rmf} "$target_tmp"
        fi
      }

      # API overrides win on each activation; unlisted values remain mutable in DMS.
      ${mergeJson "settings" settingsOverridesFile settingsDefaultsFile true}
      ${mergeJson "plugins" pluginOverridesFile pluginDefaultsFile true}
      ${mergeJson "clipboard" clipboardOverridesFile clipboardDefaultsFile false}
      ${mergeJson "session" sessionOverridesFile sessionDefaultsFile true}
    fi
  ''
