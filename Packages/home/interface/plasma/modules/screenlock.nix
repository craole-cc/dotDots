{src}: {
  kscreenlocker = {
    appearance = {
      alwaysShowClock = true;
      showMediaControls = false;
      # wallpaper = src + "/Assets/Images/wallpapers/wallpaper_lockscreen_dark.jpg";
      wallpaperPictureOfTheDay = {
        provider = "bing";
      };
      # wallpaperSlideShow = {
      #   path = src + "/Assets/Images/wallpapers";
      #   interval = 1200;
      # };
    };
    autoLock = true;
    lockOnResume = true;
    lockOnStartup = false;
    passwordRequired = false;
    timeout = 10;
  };
}
