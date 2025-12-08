{
  mkIf,
  enable,
  ...
}: {
  config = mkIf enable {
    services = {
      desktopManager.cosmic = {
        enable = true;
        xwayland.enable = true;
        showExcludedPkgsWarning = false;
      };

      displayManager.cosmic-greeter.enable = true;
    };
  };
}
