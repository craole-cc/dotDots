{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) host;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
in
{
  config =
    mkIf
      (elem host.base [
        "laptop"
        "chromebook"
        "notebook"
      ])
      {
        hardware = {
          bluetooth = {
            enable = true;
            settings.General = {
              Enable = "Source,Sink,Media,Socket";
              Experimental = true;
            };
          };
          enableRedistributableFirmware = true;
          cpu.${host.cpu.brand}.updateMicrocode = true;
          sensor = {
            iio.enable = true;
            hddtemp.enable = true;
          };
        };

        services = {
          blueman.enable = true;
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

        security.rtkit.enable = true;
        sound.enable = false;

        environment.systemPackages = with pkgs; [
          pavucontrol
          easyeffects
          qjackctl
          brightnessctl
        ];
      };
}
