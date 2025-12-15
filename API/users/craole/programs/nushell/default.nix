{
  lib,
  user,
  policies,
  ...
}:
let
  app = "nushell";
  enable = policies.dev && lib.elem app user.shells;
in
{
  programs.${app} = {
    inherit enable;
  };
}
