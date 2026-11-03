{
  configHome,
  config,
  inputs,
  lix,
  ...
}: let
  inherit (inputs.home-manager.lib.hm.dag) entryBetween;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.toolkit.binaries) mkdirp mvt readlink;
  enabled = attrNames (filterAttrs (_: plugin: plugin.enable) config.programs.dank-material-shell.plugins);

  pluginPath = let
    base = "${configHome}dms/plugins";
  in {
    targetDir = base;
    backupDir = "${base}.dms-backup";
    build = name: "dms/plugins/${name}";
  };

  # Permit the selected paths through collision checking; migrate them only
  # after the write boundary and before Home Manager installs its links.
  files = listToAttrs (map (name: {
      name = pluginPath.build name;
      value.force = true;
    })
    enabled);

  activation = entryBetween ["linkGeneration"] ["writeBoundary"] ''
    plugin_dir=${escapeShellArg pluginPath.targetDir}
    backup_dir=${escapeShellArg pluginPath.backupDir}
    for plugin in ${escapeShellArgs enabled}; do
      target="$plugin_dir/$plugin"
      if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        continue
      fi
      if [ -L "$target" ]; then
        case "$(${readlink} "$target")" in
          /nix/store/*-home-manager-files/*) continue ;;
        esac
      fi
      if [ -n "$DRY_RUN_CMD" ]; then
        echo "Would back up legacy DMS plugin: $target"
      else
        # Keep backups outside the scanned plugin directory. Move the original
        # link itself, preserving its target for restoration to the original path.
        ${mkdirp} "$backup_dir"
        ${mvt} --backup=numbered -- "$target" "$backup_dir/$plugin"
      fi
    done
  '';
in {
  inherit files activation;
  migration = activation;
}
