{host, lix, ...}: let
  primary = host.principals.primary;
in {
  services = {
    openssh.enable = true;
    tailscale.enable = lix.lists.elem "vpn" host.functionalities;
    libinput.enable = lix.lists.elem "touchpad" host.functionalities;
    printing.enable = true;

    pipewire = {
      enable = lix.lists.elem "audio" host.functionalities;
      alsa.enable = lix.lists.elem "audio" host.functionalities;
      alsa.support32Bit = lix.lists.elem "audio" host.functionalities;
      pulse.enable = lix.lists.elem "audio" host.functionalities;
    };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = primary.autoLogin;
        user = primary.name;
      };
    };

    desktopManager.plasma6.enable = lix.lists.elem "plasma" host.interface.desktops;

    xserver = {
      enable = false;
      xkb = {
        layout = primary.interface.keyboard.layout;
        variant = primary.interface.keyboard.variant;
      };
    };
  };
}
