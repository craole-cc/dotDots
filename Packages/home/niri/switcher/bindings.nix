{user, ...}: {
  settings.keys = {
    modifier = user.interface.keyboard.modifier or "Super";
    switch = {
      next = "Tab";
      prev = "Shift+Tab";
    };
  };
}
