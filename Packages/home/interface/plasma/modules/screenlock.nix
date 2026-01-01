{src}: {
  kscreenlocker = {
    lockOnResume = true;
    timeout = 10;
    appearance = {
      alwaysShowClock = true;
      showMediaControls = false;
      # wallpaper = src + "/Assets/Images/wallpapers/wallpaper_lockscreen_dark.jpg";
      wallpaperPictureOfTheDay = {
        provider = "bing";
      };
      # wallpaperSlideShow = {
      #   path = src + "/Assets/Images/wallpapers";
      # };
    };
  };
}
