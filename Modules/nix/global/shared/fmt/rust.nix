{
  programs = {
    rustfmt.enable = true;
    leptosfmt.enable = true;
  };

  settings.formatter = {
    rustfmt.priority = 1;
    leptosfmt.priority = 2;
  };
}
