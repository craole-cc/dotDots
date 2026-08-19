{
  programs = {
    alejandra.enable = true;
    statix.enable = true;
  };

  settings.formatter = {
    alejandra.priority = 1;
    statix.priority = 2;
  };
}
