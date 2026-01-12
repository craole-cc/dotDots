{fonts, ...}: {
  appearance = {
    rounding.scale = 1;
    spacing.scale = 1;
    padding.scale = 1;
    font = {
      family = {
        sans = fonts.sans or "Monaspace Radon NF Light";
        mono = fonts.monospace or "monospace";
        material = fonts.material or "Material Symbols Sharp";
        clock = fonts.clock or "Rubik";
      };
      size.scale = 0.90;
    };
    anim.durations.scale = 1;
    transparency = {
      enabled = true;
      base = 1;
      layers = 0.25;
    };
  };

  general = {
    apps = {
      terminal = ["foot"];
      audio = ["pavucontrol"];
      playback = ["mpv"];
      explorer = ["spacedrive" "dolphin"];
    };
    idle = {
      lockBeforeSleep = true;
      inhibitWhenAudio = true;
      timeouts = [
        {
          idleAction = "lock";
          timeout = 180;
        }
        {
          idleAction = "dpms off";
          returnAction = "dpms on";
          timeout = 300;
        }
        {
          idleAction = [
            "systemctl"
            "suspend-then-hibernate"
          ];
          timeout = 600;
        }
      ];
    };
    battery = {
      warnLevels = [
        {
          icon = "battery_android_frame_2";
          level = 20;
          message = "You might want to plug in a charger";
          title = "Low battery";
        }
        {
          icon = "battery_android_frame_1";
          level = 10;
          message = "You should probably plug in a charger <b>now</b>";
          title = "Did you see the previous message?";
        }
        {
          critical = true;
          icon = "battery_android_alert";
          level = 5;
          message = "PLUG THE CHARGER RIGHT NOW!!";
          title = "Critical battery level";
        }
      ];
      criticalLevel = 3;
    };
  };

  notifs = {
    expire = true;
    defaultExpireTimeout = 5000;
    clearThreshold = 0.3;
    expandThreshold = 20;
    actionOnClick = false;
    groupPreviewNum = 3;
    sizes = {
      width = 400;
      image = 41;
      badge = 20;
    };
  };

  osd = {
    enabled = true;
    hideDelay = 2000;
    enableBrightness = true;
    enableMicrophone = true;
    sizes = {
      sliderWidth = 30;
      sliderHeight = 150;
    };
  };

  utilities = {
    enabled = true;
    maxToasts = 4;
    sizes = {
      width = 430;
      toastWidth = 430;
    };
    toasts = {
      configLoaded = true;
      chargingChanged = true;
      gameModeChanged = true;
      dndChanged = true;
      audioOutputChanged = true;
      audioInputChanged = true;
      capsLockChanged = true;
      numLockChanged = true;
      kbLayoutChanged = true;
      vpnChanged = true;
      nowPlaying = true;
    };
    vpn = {
      enabled = false;
      provider = ["netbird"];
    };
  };
}
