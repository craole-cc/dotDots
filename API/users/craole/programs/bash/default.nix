{
  lib,
  user,
  policies,
  ...
}:
let
  app = "bash";
  enable = policies.dev && lib.elem app user.shells;
in
{
  programs.${app} = {
    inherit enable;
  };
}
