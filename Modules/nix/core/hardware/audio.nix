{
  config,
  host,
  lix,
  ...
}: let
  dom = "hardware";
  mod = "audio";

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption;
in
  mkConfig {
    inherit config dom mod;
    options = {
      enable =
        mkEnableOption mod
        // {default = host.hardware.hasAudio;};
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
