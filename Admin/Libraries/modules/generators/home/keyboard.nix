{
  lib,
  user,
  host,
  ...
}: let
  inherit (lib.strings) toUpper;
  fromUser = user.interface.keyboard or {};
  fromHost = host.interface.keyboard or {};
in {
  _module.args.keyboard = {
    mod = toUpper (
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
}
