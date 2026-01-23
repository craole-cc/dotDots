{
  locale,
  paths,
  ...
}: {
  services = {
    audioIncrement = 0.1;
    brightnessIncrement = 0.1;
    defaultPlayer = "Elisa";
    gpuType = "";
    maxVolume = 1;
    smartScheme = true;
    useFahrenheit = false;
    useTwelveHourClock = true;
    visualiserBars = 45;
    weatherLocation = locale.city;

    playerAliases = [
      {
        from = "com.github.th_ch.youtube_music";
        to = "YT Music";
      }
    ];
  };

  paths = with paths; {
    wallpaperDir = wallpapers;
    sessionGif = avatars.session;
    mediaGif = avatars.media;
  };
}
