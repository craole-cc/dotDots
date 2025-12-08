{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;

  #~@ Active host exported from the registry
  host = config.${DOM}.host or null;

  #~@ Treat the session as X11 when the host interface protocol is xserver
  isXserver = host != null && (host.interface.protocol or "wayland") == "xserver";
in
{
  config = mkIf isXserver {
    services.xserver = {
      enable = true;
      videoDrivers = if config.hardware.nvidia.modesetting.enable then [ "nvidia" ] else [ ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
