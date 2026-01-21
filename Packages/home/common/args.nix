{
  lib,
  user,
  host,
  ...
}: let
  inherit (lib.strings) toUpper;
in {
  _module.args = {
    city = host.localization.city or "Mandeville, Jamaica";

    fonts =
      user.interface.style.fonts or  host.interface.style.fonts or {
        emoji = "Noto Color Emoji";
        monospace = "Maple Mono NF";
        sans = "Monaspace Radon Frozen";
        serif = "Noto Serif";
        material = "Material Symbols Sharp";
        clock = "Rubik";
      };

    keyboard = let
      fromUser = user.interface.keyboard or {};
      fromHost = host.interface.keyboard or {};
    in {
      mod =
        toUpper (
          fromUser.modifier or
      fromHost.modifier or
      "Super"
        );
      swapCapsEscape =
        fromUser.swapCapsEscape or
      fromHost.swapCapsEscape or
      null;
      vimKeybinds =
        fromUser.vimKeybinds or
      fromHost.vimKeybinds or
      false;
    };
  };
}
