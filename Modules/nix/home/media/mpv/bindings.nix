{
  bindings = {
    WHEEL_UP = "seek 10";
    WHEEL_DOWN = "seek -10";
    "Alt+0" = "set window-scale 0.5";
  };

  extraInput = ''
    esc         quit                        #? Quit
    #           script-binding uosc/video   #? Video tracks
  '';
}
