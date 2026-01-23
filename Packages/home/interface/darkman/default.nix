{
  host,
  lib,
  locale,
  paths,
  pkgs,
  user,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (pkgs) writeShellScript sd dbus dconf libnotify;

  #~@ Location
  lat = locale.latitude or null;
  lng = locale.longitude or null;
  usegeoclue = (locale.provider or "manual") == "geoclue2";

  #~@ Style
  style = user.interface.style or host.interface.style or {};
  switch = style.autoSwitch or false;

  #~@ Paths
  dots = paths.dots;
  userApi = paths.api.user;

  #~@ Enable condition
  enable =
    switch
    && (lat != null)
    && (lng != null)
    && (dots != null);

  #~@ Mode script generator
  mkModeScript = mode: let
    sd = "${sd}/bin/sd";
    dbus = "${dbus}/bin/dbus-send";
    dconf = "${dconf}/bin/dconf";
    note = "${libnotify}/bin/notify-send";

    #> Portal mode: 1 = prefer dark, 2 = prefer light
    portalMode =
      if mode == "dark"
      then "1"
      else "2";
  in
    writeShellScript "darkman-${mode}-mode" ''
      set -euo pipefail

      #> Update theme mode in user configuration
      ${sd} 'current = "(dark|light)"' 'current = "${mode}"' "${userApi}"

      #> Update the freedesktop portal setting
      ${dbus} --session --dest=org.freedesktop.portal.Desktop \
        --type=method_call /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.ReadOne \
        string:'org.freedesktop.appearance' string:'color-scheme' \
        uint32:${portalMode} 2>/dev/null || true

      #> Update GTK/Qt theming preference
      ${dconf} write /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'" || true

      #> Update wallpapers for all monitors using wallman
      ${paths.wallpapers.manager} set --polarity ${mode} || true

      #> Notify
      ${note} "Theme Switched" "Switched to ${mode} mode" -t 2000 || true
    '';
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = mkModeScript "dark";
    lightModeScripts.nixos-theme = mkModeScript "light";
  };
}
