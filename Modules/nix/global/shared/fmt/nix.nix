{
  programs = {
    alejandra.enable = true;
    statix.enable = true;
    deadnix.enable = false;
  };

  settings.formatter = {
    alejandra.priority = 2;
    statix.priority = 1;
  };
}
