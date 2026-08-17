{pkgs, ...}: {
  plugins = with pkgs.nushellPlugins; [
    # dbus #? Broken
    # desktop_notifications
    formats
    gstat
    highlight
    polars
    query
    semver
    # net #? Broken
    skim
    # units #? Broken
  ];
}
