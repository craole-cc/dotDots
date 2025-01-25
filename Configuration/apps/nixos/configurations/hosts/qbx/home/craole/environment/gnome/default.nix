{ config, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    videoDrivers = if config.hardware.nvidia.modesetting.enable then [ "nvidia" ] else [ ];
    # libinput.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  systemd.services = {
    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };
}
