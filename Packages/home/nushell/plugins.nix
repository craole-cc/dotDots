{pkgs, ...}: {
  plugins = with pkgs.nushellPlugins; [
    dbus
    desktop_notifications
    formats
    gstat
    highlight
    polars
    query
    semver
    net
    skim
    units
  ];
}
