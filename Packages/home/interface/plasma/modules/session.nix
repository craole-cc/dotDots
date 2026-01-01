{src}: {
  kscreenlocker = {
    appearance = {
      alwaysShowClock = true;
      showMediaControls = true;
      wallpaperPictureOfTheDay = {
        provider = "bing";
        updateOverMeteredConnection = false;
      };
    };
    autoLock = true;
    lockOnResume = true;
    lockOnStartup = false;
    passwordRequired = true;
    passwordRequiredDelay = 5;
    timeout = 10;
  };

  session = {
    sessionRestore = {
      restoreOpenApplicationsOnLogin = "whenSessionWasManuallySaved";
      excludeApplications = [];
    };
    general.askForConfirmationOnLogout = false;
  };
}
