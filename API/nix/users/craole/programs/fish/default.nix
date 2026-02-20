{
  lib,
  user,
  policies,
  ...
}: let
  app = "fish";
  enable = policies.dev && lib.elem app user.shells;
in {
  programs.${app} = {
    inherit enable;
  };
}
