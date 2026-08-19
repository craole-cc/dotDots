{
  programs = {
    alejandra.enable = true;
    statix.enable = true;
    deadnix.enable = false;
  };

  settings.formatter = {
    alejandra.priority = 1;
    statix.priority = 2;
    deadnix.priority = 3;
  };
}
