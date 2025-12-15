{
  programs.zed-editor.userSettings.terminal = {
    shell = "system";
    dock = "bottom";
    default_width = 640;
    default_height = 480;
    font_size = 24;
    working_directory = "current_project_directory";
    blinking = "terminal_controlled";
    alternate_scroll = "off";
    option_as_meta = true;
    copy_on_select = true;
    button = false;
    env = { };
    line_height = "standard";
    toolbar = {
      title = true;
      buttons = false;
    };
  };
}
