{
  lib,
  user,
  ...
}: let
  app = "nushell";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed || elem app user.shells;
in {
  programs.${app}.enable = isAllowed;
  imports = [];
}
