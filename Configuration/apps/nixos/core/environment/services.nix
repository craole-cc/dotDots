{
  specialArgs,
  ...
}:
{
  services = {
    kmscon = {
      enable = true;
      autologinUser = specialArgs.alpha;
    };

    blueman = {
      enable = true; # TODO for devices with bluetooth
    };

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="hidraw", GROUP="users", MODE="0660", TAG+="uaccess"
    '';

    upower = {
      enable = true;
    };

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
    };

    libinput = {
      enable = true; # TODO for devices with mouse or touchpad
    };

    tailscale = {
      enable = true;
    };

    # ollama = {
    #   enable = true;
    #   loadModels = [
    #     "mistral-nemo"
    #     # "yi-coder:9b"
    #   ];
    # };

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
    };
  };
}
