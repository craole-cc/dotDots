{
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  hasAudio = lib.lists.elem "audio" (host.functionalities or []);
in {
  services = {
    pipewire = mkIf hasAudio {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    pulseaudio.enable = false;
  };
  security.rtkit.enable = hasAudio;
}
