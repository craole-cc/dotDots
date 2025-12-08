{host, ...}: let
  inherit (host.interface) keyboard;
in {
  niriswitcher = {
    enable = true;
    settings = {
      keys = {
        inherit (keyboard) modifier;
        # modifier = "Super";
        switch = {
          next = "Tab";
          prev = "Shift+Tab";
        };
      };
      center_on_focus = true;
      appearance = {
        system_theme = "dark";
        icon_size = 64;
      };
    };
  };
}
