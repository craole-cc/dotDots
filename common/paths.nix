{
  config,
  lix,
  host,
  user,
  paths,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.paths) getDefaults;
  defaults = getDefaults {inherit paths config host user pkgs;};
in {
  _module.args.paths = defaults;
  home = {
    packages = [defaults.wallpapers.manager];
    sessionVariables = {
      # DOTS_WALLPAPER_MANAGER = wallpapers.manager;
      # _DOTS = dots;
      # _API_HOST = api.host;
      # _API_USER = api.user;
    };
  };
}
