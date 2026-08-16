{
  hypridle = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        #? Never sleep
        # {
        #   timeout = 600;
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };
}
