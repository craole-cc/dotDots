{homeDir, ...}: {
  audio = {
    cavaFrameRate = 30;
    externalMixer = "pwvucontrol || pavucontrol";
    mprisBlacklist = [];
    preferredPlayer = "";
    visualizerType = "linear";
    volumeOverdrive = false;
    volumeStep = 5;
  };

  brightness = {
    brightnessStep = 5;
    enableDdcSupport = false;
    enforceMinimum = true;
  };

  nightLight = {
    autoSchedule = true;
    dayTemp = "6500";
    enabled = true;
    forced = false;
    manualSunrise = "06:30";
    manualSunset = "18:30";
    nightTemp = "4000";
  };

  screenRecorder = {
    audioCodec = "opus";
    audioSource = "default_output";
    colorRange = "limited";
    copyToClipboard = true;
    directory = homeDir + "/Videos/Recordings";
    frameRate = 60;
    quality = "ultra";
    showCursor = true;
    videoCodec = "h264";
    videoSource = "portal";
  };
}
