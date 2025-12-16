{
  lib,
  user,
  ...
}: let
  app = "nushell";
  inherit (lib.lists) elem;
  inherit (user) enable;
  isAllowed = elem app enable || elem app user.shells;
in {
  programs.${app}.enable = isAllowed;
  imports = [];
}
