{
  enable,
  mkIf,
  ...
}: {
  services = mkIf enable {
    iio-niri.enable = true;
  };
}
