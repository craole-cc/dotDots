{ specialArgs, ...}:
{
  services = {
    blueman = {
      enable = true;
    }; # TODO for devices with bluetooth

    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.75";
      };
      temperature = {
        day = 5500;
        night = 3800;
      };
    }; # TODO for devices with battery

    kmscon = {
      enable = true;
      autologinUser = specialArgs.alpha;
    };

    libinput = {
      enable = true;
    }; # TODO for devices with mouse or touchpad

    ollama = {
      enable = true;
      loadModels = [
        "mistral-nemo"
        # "yi-coder:9b"
      ];
    }; # TODO for devices with 16GB memory

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        context.properties.default.clock = {
          rate = 48000;
          quantum = 32;
          min-quantum = 32;
          max-quantum = 32;
        };
      };
    }; # TODO for devices with audio

    tailscale = {
      enable = true;
    };

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="hidraw", GROUP="users", MODE="0660", TAG+="uaccess"
    '';

    upower = {
      enable = true;
    }; # TODO for devices with battery
  };
}
