{
  lib,
  user,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "yazi";
  isAllowed = elem app enable;
in {programs.${app}.enable = isAllowed;}
