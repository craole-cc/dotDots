{ pkgs, ... }:

{
  services.xserver.displayManager.sddm = {
    enable = true;
    settings = {
      Autologin = {
        # Session = "plasma.desktop";
        Session = "none+qtile";
        User = "craole";
      };
    };
  };
}
