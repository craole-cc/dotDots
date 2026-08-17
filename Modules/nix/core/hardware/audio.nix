{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "hardware";
    mod = "audio";
  };
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = host.hardware.hasAudio;
      };
    };
    outputs = {
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
