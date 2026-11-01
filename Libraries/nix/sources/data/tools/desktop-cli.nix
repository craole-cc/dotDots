{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  dbus = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "D-Bus command-line tools, including dbus-send and dbus-monitor";
    discover = true; #? dbus-send, dbus-monitor, ...
    exe = "dbus-send";
    aliases = mergeDisjoint [
      (mkAliasFamily "dbus-monitor" {
        aliasPrefix = "dbusMonitor";
        Session = {
          args = ["--session"];
          description = "watch messages on the session bus";
        };
        System = {
          args = ["--system"];
          description = "watch messages on the system bus";
        };
      })
      (mkAliasFamily "dbus-send" {
        aliasPrefix = "dbus";
        SessionCall = {
          args = ["--session" "--print-reply" "--type=method_call" "--dest"];
          description = "call a session bus method and print the reply (caller supplies destination, path, and method)";
        };
        SystemCall = {
          args = ["--system" "--print-reply" "--type=method_call" "--dest"];
          description = "call a system bus method and print the reply (caller supplies destination, path, and method)";
        };
      })
    ];
  };

  glib = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "gdbus, gio, and gsettings";
    discover = true; #? gdbus, gio, gsettings, ...
    exe = "gsettings";
    aliases = mergeDisjoint [
      (mkAliasFamily "gdbus" {
        aliasPrefix = "g";
        Call = {
          args = ["call"];
          description = "call a method on a D-Bus object";
        };
        Introspect = {
          args = ["introspect" "--session" "--dest"];
          description = "introspect a session bus service (caller supplies destination and path)";
        };
        Monitor = {
          args = ["monitor" "--session" "--dest"];
          description = "watch signals from a session bus service";
        };
      })
      (mkAliasFamily "gsettings" {
        aliasPrefix = "g";
        Get = {
          args = ["get"];
          description = "read a caller-specified GSettings key";
        };
        GetDI = {
          args = ["get" "org.gnome.desktop.interface"];
          description = "read a GNOME desktop interface setting";
        };
        ListAll = {
          args = ["list-recursively"];
          description = "list every key and value in a schema";
        };
        Reset = {
          args = ["reset"];
          description = "reset a GSettings key to its default";
        };
        Set = {
          args = ["set"];
          description = "set a caller-specified GSettings key";
        };
        SetDI = {
          args = ["set" "org.gnome.desktop.interface"];
          description = "set a GNOME desktop interface setting";
        };
      })
      (mkAliasFamily "gio" {
        Info = {
          args = ["info"];
          description = "show file information and attributes";
        };
        Open = {
          args = ["open"];
          description = "open a file or URI with its default application";
        };
        Trash = {
          args = ["trash"];
          description = "move files to the trash";
        };
      })
    ];
  };

  libnotify = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "desktop notifications";
    exe = "notify-send";
    aliases = mergeDisjoint [
      (mkAliasFamily "notify-send" {
        aliasPrefix = "notify";
        App = {
          args = ["--app-name"];
          description = "send a notification under a caller-specified application name";
        };
        Critical = {
          args = ["--urgency=critical"];
          description = "send a critical-urgency notification";
        };
        Expire = {
          args = ["--expire-time"];
          description = "send a notification that expires after a caller-specified time in milliseconds";
        };
        Icon = {
          args = ["--icon"];
          description = "send a notification with a caller-specified icon";
        };
        Transient = {
          args = ["--transient"];
          description = "send a notification that is not kept in notification history";
        };
      })
    ];
  };

  wl-clipboard = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "wl-copy, wl-paste, and related Wayland clipboard tools";
    discover = true; #? wl-copy, wl-paste
    exe = "wl-copy";
    aliases = mergeDisjoint [
      (mkAliasFamily "wl-copy" {
        aliasPrefix = "wlCopy";
        Clear = {
          args = ["--clear"];
          description = "clear the clipboard";
        };
        Primary = {
          args = ["--primary"];
          description = "copy to the primary selection";
        };
        Trim = {
          args = ["--trim-newline"];
          description = "copy without the trailing newline";
        };
        Type = {
          args = ["--type"];
          description = "copy using a caller-specified MIME type";
        };
      })
      (mkAliasFamily "wl-paste" {
        aliasPrefix = "wlPaste";
        List = {
          args = ["--list-types"];
          description = "list the MIME types available on the clipboard";
        };
        NoNewline = {
          args = ["--no-newline"];
          description = "paste without adding a trailing newline";
        };
        Primary = {
          args = ["--primary"];
          description = "paste from the primary selection";
        };
        Type = {
          args = ["--type"];
          description = "paste a caller-specified MIME type";
        };
        Watch = {
          args = ["--watch"];
          description = "run a command each time the clipboard changes";
        };
      })
    ];
  };

  xdg-utils = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "xdg-open, xdg-mime, and related desktop integration tools";
    discover = true; #? xdg-open, xdg-mime, ...
    exe = "xdg-open";
    aliases = mergeDisjoint [
      (mkAliasFamily "xdg-settings" {
        aliasPrefix = "xdg";
        BrowserGet = {
          args = ["get" "default-web-browser"];
          description = "show the default web browser";
        };
        BrowserSet = {
          args = ["set" "default-web-browser"];
          description = "set the default web browser (caller supplies the .desktop file)";
        };
        SettingsGet = {
          args = ["get"];
          description = "read a desktop setting";
        };
        SettingsSet = {
          args = ["set"];
          description = "change a desktop setting";
        };
      })
      (mkAliasFamily "xdg-mime" {
        aliasPrefix = "xdgMime";
        Default = {
          args = ["default"];
          description = "set the default application for a MIME type (caller supplies both)";
        };
        QueryDefault = {
          args = ["query" "default"];
          description = "show the default application for a MIME type";
        };
        QueryFiletype = {
          args = ["query" "filetype"];
          description = "show the MIME type of a file";
        };
      })
    ];
  };
}
