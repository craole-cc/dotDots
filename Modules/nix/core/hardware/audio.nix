{
  config,
  host,
  lib,
  top,
  lix,
  ...
}: let
  dom = "hardware";
  mod = "audio";
  cfg = config.${top}.resolved.${dom}.${mod};

  hw = host.hardware;

  inherit (lix.modules.construction) mkConfig;
  inherit (lib.options.construction) mkEnableOption;
in
  {
    options.${top}.resolved.${dom}.${mod} = {
      enable = mkEnableOption mod // {default = hw.hasAudio;};
    };
  }
  // mkConfig {
    payload = {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
    };
    condition = cfg.enable;
  }
