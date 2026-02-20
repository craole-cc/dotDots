{
  user,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "zsh";
  isAllowed = elem app enable && lib.elem app user.shells;
in {
  programs.${app}.enable = isAllowed;
}
