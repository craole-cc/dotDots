{
  city,
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
    weatherLocation = city;

    playerAliases = [
      {
        from = "com.github.th_ch.youtube_music";
        to = "YT Music";
      }
    ];
  };

  paths = with paths; {
    wallpaperDir = wallpapers;
    sessionGif = mkDefault "avatar" "root:/assets/kurukuru.gif";
    mediaGif = mkDefault "mediaAvatar" "root:/assets/bongocat.gif";
  };
}
