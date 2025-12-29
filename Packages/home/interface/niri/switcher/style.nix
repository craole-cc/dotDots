{
  settings = {
    appearance = {
      system_theme = "dark";
      icon_size = 64;
    };
  };

  style = ''
    .application-name {
      opacity: 1;
      color: rgba(255, 255, 255, 0.6);
    }
    .application.selected .application-name {
      color: rgba(255, 255, 255, 1);
    }
  '';
}
