{
  programs = {
    ruff-format.enable = true;
    ruff-check.enable = true;
  };

  settings.formatter = {
    ruff-format.priority = 1;
    ruff-check.priority = 2;
  };
}
