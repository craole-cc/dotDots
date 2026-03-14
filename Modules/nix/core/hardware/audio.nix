{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "hardware";
  mod = "audio";
  cfg = config.${top}.${dom}.${mod};

  hw = host.hardware;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = hw.hasAudio;};
  };

  config = mkIf cfg.enable {
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
}
