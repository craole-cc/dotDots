{
  toolkit,
  config,
  entryAfter,
  lix,
  ...
}: let
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs;
  inherit (lix.modules.construction) mkIf;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (toolkit.binaries) gum installDm jaq mkdirp mktemp rmf;
  inherit (config.xdg) configHome;

  cfg = config.programs.dank-material-shell;
  enabled = filterAttrs (_: plugin: plugin.enable) cfg.plugins;
  flags = toolkit.write.json "dms-enabled-plugins.json" (
    mapAttrs (_: _: {enabled = true;}) enabled
  );
in {
  activation = mkIf (!cfg.managePluginSettings) (entryAfter ["configureDmsTheme" "linkGeneration"] ''
    settings=${escapeShellArg "${configHome}/dms/plugin_settings.json"}
    if [ -n "$DRY_RUN_CMD" ]; then
      ${gum} log --level info "Would enable declared DMS plugins in $settings"
    else
      if [ -L "$settings" ]; then
        ${gum} log --level error "Refusing to replace managed DMS plugin settings symlink: $settings" >&2
        exit 1
      fi
      ${mkdirp} ${escapeShellArg "${configHome}/dms"}
      tmp="$(${mktemp} "$settings.tmp.XXXXXX")"
      trap '${rmf} "$tmp"' EXIT
      if [ -f "$settings" ]; then
        ${jaq} --slurpfile declared ${flags} '. * $declared[0]' "$settings" > "$tmp"
      else
        ${jaq} '.' ${flags} > "$tmp"
      fi
      ${installDm} 0600 "$tmp" "$settings"
      ${rmf} "$tmp"
      trap - EXIT
    fi
  '');
}
