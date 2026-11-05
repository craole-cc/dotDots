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
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.filesystem.construction) concatPath;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.toolkit.binaries) chmod0600 cmps dirname gumLogError gumLogInfo install0644 jaq jaqn mkdirp mktemp mvf readlinkf rmf;
  inherit (lix.toolkit.write) json;
  inherit (themes) catppuccin foot ghostty hermes kitty;
  inherit (themes) icons;

  forSh = escapeShellArg;
  asJSON = root: stem:
    forSh (concatPath {
      inherit root;
      stem = ["dms" "${stem}.json"];
    });

  raw = import ./defaults {inherit lix;};
  toOutput = import ./settings-output.nix {inherit lix;};

  output = {
    declared = toOutput (dms.settings or {});
    stock = toOutput (raw.settings or {});
  };

  settings = {
    overrides = output.declared.settings;
    defaults = recursiveUpdate output.stock.settings {
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
  };

  plugins = {
    overrides = dms.plugins or {};
    defaults = raw.plugins or {};
  };

  clipboard = {
    overrides = output.declared.clipboardSettings;
    defaults = output.stock.clipboardSettings;
  };

  session = {
    overrides = dms.session or {};
    defaults = recursiveUpdate (raw.session or {}) {
      isLightMode = style.mode == "light";
      themeModeAutoEnabled = user.theme.modes.autoSwitch or false;
    };
  };

  toFiles = name: set: {
    overrides = json "dms-${name}-overrides.json" set.overrides;
    defaults = json "dms-${name}-defaults.json" set.defaults;
  };

  files = {
    settings = toFiles "settings" settings;
    plugins = toFiles "plugin-settings" plugins;
    clipboard = toFiles "clipboard-settings" clipboard;
    session = toFiles "session" session;
  };
in
  entryAfter ["writeBoundary"] ''
    gum_log_info=${forSh gumLogInfo} \
    gum_log_error=${forSh gumLogError} \
    jaq=${forSh jaq} \
    jaqn=${forSh jaqn} \
    mkdirp=${forSh mkdirp} \
    dirname=${forSh dirname} \
    install0644=${forSh install0644} \
    mktemp=${forSh mktemp} \
    readlinkf=${forSh readlinkf} \
    cmps=${forSh cmps} \
    chmod0600=${forSh chmod0600} \
    mvf=${forSh mvf} \
    rmf=${forSh rmf} \
    settings=${asJSON configHome "settings"} \
    plugins=${asJSON configHome "plugin_settings"} \
    clipboard=${asJSON configHome "clsettings"} \
    session=${asJSON stateHome "session"} \
    hermes_skin=${forSh hermes.skinPath} \
    foot_theme=${forSh foot.path} \
    foot_fallback=${forSh foot.fallback} \
    ghostty_opacity=${forSh ghostty.opacity.path} \
    ghostty_opacity_fallback=${forSh ghostty.opacity.fallback} \
    kitty_opacity=${forSh kitty.opacity.path} \
    kitty_opacity_fallback=${forSh kitty.opacity.fallback} \
    settings_overrides=${forSh files.settings.overrides} \
    settings_defaults=${forSh files.settings.defaults} \
    plugins_overrides=${forSh files.plugins.overrides} \
    plugins_defaults=${forSh files.plugins.defaults} \
    clipboard_overrides=${forSh files.clipboard.overrides} \
    clipboard_defaults=${forSh files.clipboard.defaults} \
    session_overrides=${forSh files.session.overrides} \
    session_defaults=${forSh files.session.defaults} \
    dry_run_cmd="''${DRY_RUN_CMD:-}" \
    sh ${./activation.sh}
  ''
