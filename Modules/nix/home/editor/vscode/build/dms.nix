{
  config,
  cfg,
  entryAfter,
  lix,
  bins,
  app,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.strings.transformation) escapeShellArg;

  source = escapeShellArg (concat {
    root = config.programs.dank-material-shell.package.src;
    stem = ["quickshell" "matugen" "vsix-build"];
  });
in
  optionalAttrs cfg.features.ui.dms {
    seedDmsVSCodeTheme = entryAfter ["linkGeneration"] ''
      source=${source}
      theme_version=$(${bins.jaq} -er '.version | strings | select(length > 0)' "$source/package.json")
      theme_dir="danklinux.dms-theme-$theme_version"

      seed_dms_theme() {
        root="$1"
        target="$root/$theme_dir"

        ${bins.mkdir} -p "$root"

        for candidate in "$root"/danklinux.dms-theme-*; do
          [ -e "$candidate" ] || [ -L "$candidate" ] || continue
          [ "$candidate" = "$target" ] || ${bins.rmf} "$candidate"
        done

        if [ -L "$target" ] || [ ! -f "$target/package.json" ]; then
          ${bins.rmf} "$target"
          ${bins.cp} -RL "$source" "$target"
        fi
        ${bins.chmod} -R u+w "$target"
      }

      seed_dms_theme "${app.directories.extension}"
    '';
  }
