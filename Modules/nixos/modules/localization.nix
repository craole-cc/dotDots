{
  location = {
    latitude = 18.015;
    longitude = 77.49;
  };
  time.timeZone = "America/Jamaica";
  i18n.defaultLocale = "en_US.UTF-8";

  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "0.75";
    };
    temperature = {
      day = 5500;
      night = 3800;
    };
  };
}
