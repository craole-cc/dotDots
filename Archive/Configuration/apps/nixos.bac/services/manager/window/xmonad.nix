{ ... }:

{
  services.xserver = {
    # xrandrHeads = [{ output = "HDMI-0"; primary = true; } { output = "VGA-0"; }];
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = haskellPackages: [
          haskellPackages.dbus
          haskellPackages.List
          haskellPackages.monad-logger
          haskellPackages.xmonad
          haskellPackages.xmobar
          haskellPackages.xmonad-screenshot
        ];
        configFile = "/home/craole/DOTS/Config/tools/interface/xmonad/xmonad.hs"
          };
      };
      services.xserver.displayManager.sessionCommands = ''
        xset -dpms  # Disable Energy Star, as we are going to suspend anyway and it may hide "success" on that
        xset s blank # `noblank` may be useful for debugging
        xset s 300 # seconds
        ${pkgs.lightlocker}/bin/light-locker --idle-hint &
      '';
      environment.systemPackages = with pkgs; [
        haskellPackages.haskell-language-server
        haskellPackages.hoogle
        cabal-install
        stack
      ];
    };
  }
