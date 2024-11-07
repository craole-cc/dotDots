{ ... }:
{
  networking = {
    networkmanager.enable = true;
    useDHCP = false;
    nameservers = [
      "1.1.1.1" # @ Cloudflare
      "9.9.9.9" # @ Quad9
      "8.8.8.8" # @ Google
    ];
  };
  programs.nm-applet.enable = true;
}
