{ pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      autorun = true;
      layout = "us";
      xkbVariant = "";
      desktopManager.xterm.enable = false;
      libinput.enable = true;
    };
    autorandr.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wev
    fuzzel
    foot
  ];
}
