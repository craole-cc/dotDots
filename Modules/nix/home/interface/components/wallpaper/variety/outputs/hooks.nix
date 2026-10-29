# Build the backend hooks unless the user supplies custom executable paths.
{
  cfg,
  lix,
  controller,
}: let
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.sources.access) getExe';
  inherit (lix.toolkit.write) script;

  hook = action:
    if cfg.scripts.${action} != null
    then toString cfg.scripts.${action}
    else
      script "variety-${action}-wallpaper" ''
        exec ${getExe' controller "varietyctl"} ${escapeShellArg action} "$@"
      '';
in {
  setWallpaper = hook "set";
  getWallpaper = hook "get";
  setLockscreen = hook "set-lockscreen";
}
