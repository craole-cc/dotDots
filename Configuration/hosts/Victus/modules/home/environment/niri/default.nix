{
  host,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (host.interface) windowManager keyboard;
  enable = windowManager == "niri";
in {
  config = mkIf enable {
    programs = {
      alacritty.enable = true;
      niriswitcher = {
        inherit enable;
        settings = {
          center_on_focus = true;
          keys = import ./keys.nix {inherit keyboard;};
          appearance = import ./appearance.nix;
        };
      };
    };
  };
}
