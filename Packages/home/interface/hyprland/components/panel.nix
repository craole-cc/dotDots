{
  hyprpanel = {
    enable = true;
    settings = {
      theme = {
        font = {
          name = "Maple Mono NF";
          size = "0.75rem";
          weight = 500;
        };
      };
      bar = {
        battery.label = true;
        bluetooth.label = false;
        clock.format = "%a %b %d  %I:%M:%S %p";
        layouts = {
          "0" = {
            left = [
              "dashboard"
              "workspaces"
              "windowtitle"
            ];
            middle = [
              "clock"
              "media"
            ];
            right = [
              "volume"
              "network"
              "bluetooth"
              "systray"
              "hypridle"
              "hyprsunset"
            ];
          };
          "1" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [
              "windowtitle"
            ];
            right = [
              "volume"
              "media"
              "notifications"
            ];
          };
          "2" = {
            left = [
              "dashboard"
              "workspaces"
              "windowtitle"
            ];
            middle = [
              "clock"
            ];
            right = [
              "volume"
              "network"
              "bluetooth"
              "notifications"
            ];
          };
        };
        floating = true;
        media = {
        };
      };
      menu = {
        dashboard = {
          durectories = {
            left = {
              directory1.label = "󱧶    Documents";
              directory2.label = "󰉍    Downloads";
              directory3.label = "󰉏    Pictures";
              directory4.label = "󱂵    Home";
            };
            right = {
              directory1.label = "    Configuration";
              directory2.label = "󰚝    Projects";
              directory3.label = "󰉏    Videos";
              directory4.label = "󰩹    Trash";
            };
          };
        };
      };
    };
  };
}
