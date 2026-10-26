{
  config,
  cfg,
  entryAfter,
  lix,
  binaries,
  app,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.strings.transformation) escapeShellArg;
in
  optionalAttrs cfg.features.ui.dms {
    syncDmsVSCodeWallpaper = entryAfter ["reloadSystemd" "materialiseVSCodeProfile"] ''
      ${pkgs.systemd}/bin/systemctl --user start dotdots-foot-dms-theme-reload.service
    '';
    seedDmsVSCodeTheme = entryAfter ["linkGeneration"] ''
      source=${escapeShellArg (concat {
        root = config.programs.dank-material-shell.package.shellSource;
        stem = ["matugen" "vsix-build"];
      })}
      theme_version=$(${binaries.jaq} -er '.version | strings | select(length > 0)' "$source/package.json")
      theme_dir="danklinux.dms-theme-$theme_version"

      seed_dms_theme() {
        root="$1"
        target="$root/$theme_dir"

        ${binaries.mkdir} -p "$root"

        for candidate in "$root"/danklinux.dms-theme-*; do
          [ -e "$candidate" ] || [ -L "$candidate" ] || continue
          [ "$candidate" = "$target" ] || ${binaries.rmf} "$candidate"
        done

        if [ -L "$target" ] || [ ! -f "$target/package.json" ]; then
          ${binaries.rmf} "$target"
          ${binaries.cp} -RL "$source" "$target"
        fi
        ${binaries.chmod} -R u+w "$target"
      }

      seed_dms_theme "${app.directories.extension}"
    '';
  }
