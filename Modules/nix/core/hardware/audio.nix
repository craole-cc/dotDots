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
  cfg = config.${top}.inputs.${dom}.${mod};

  hw = host.hardware;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
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
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable =
      mkEnableOption mod
      // {
        default = hw.hasAudio;
      };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
