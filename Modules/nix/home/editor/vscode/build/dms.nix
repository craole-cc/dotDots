{
  config,
  cfg,
  entryAfter,
  lix,
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
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      if [ -S "$runtime_dir/bus" ]; then
        XDG_RUNTIME_DIR="$runtime_dir" DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
          ${pkgs.systemd}/bin/systemctl --user --no-block start dotdots-foot-dms-theme-reload.service \
          || echo "DMS appearance reload deferred until the user session is ready" >&2
      fi
    '';
    seedDmsVSCodeTheme = entryAfter ["linkGeneration"] ''
      source=${escapeShellArg (concat {
        root = config.programs.dank-material-shell.package.shellSource;
        stem = ["matugen" "vsix-build"];
      })}
      theme_version=$(${lix.toolkit.binaries.jaq} -er '.version | strings | select(length > 0)' "$source/package.json")
      theme_dir="danklinux.dms-theme-$theme_version"

      seed_dms_theme() {
        root="$1"
        target="$root/$theme_dir"

        ${lix.toolkit.binaries.mkdirp} "$root"

        for candidate in "$root"/danklinux.dms-theme-*; do
          [ -e "$candidate" ] || [ -L "$candidate" ] || continue
          [ "$candidate" = "$target" ] || ${lix.toolkit.binaries.rmrf} "$candidate"
        done

        if [ -L "$target" ] || [ ! -f "$target/package.json" ]; then
          ${lix.toolkit.binaries.rmrf} "$target"
          ${lix.toolkit.binaries.cp} -RL "$source" "$target"
        fi
        ${lix.toolkit.binaries.chmodRuw} "$target"
      }

      seed_dms_theme "${app.directories.extension}"
    '';
  }
