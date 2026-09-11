{lib, ...}: let
  inherit (lib.strings) toUpper;

  mkKeyboard = {
    host,
    user,
  }: {
    mod = toUpper (user.interface.keyboard.modifier or host.interface.keyboard.modifier or "Super");
    swapCapsEscape =
      user.interface.keyboard.swapCapsEscape or host.interface.keyboard.swapCapsEscape or null;
    vimKeybinds = user.interface.keyboard.vimKeybinds or host.interface.keyboard.vimKeybinds or false;
    bindings = user.interface.keyboard.bindings or host.interface.keyboard.bindings or {};
  };

  exports = {inherit mkKeyboard;};
in
  exports
  // {
    __rootAliases = {
      mkUserKeyboard = mkKeyboard;
    };
  }
