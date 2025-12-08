{
  enable,
  mkIf,
  ...
}: {
  services = mkIf enable {
    hypridle.enable = true;
  };

  security.pam.services.hyprlock = {};
}
