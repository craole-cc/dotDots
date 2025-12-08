{
  lib,
  host,
  ...
}:
let
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;

  inherit (host) functionalities;
  hasAudio = elem "audio" functionalities;
in
{
  config = mkIf hasAudio {
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      pulseaudio.enable = false;
    };

    security.rtkit.enable = true;
  };
}
