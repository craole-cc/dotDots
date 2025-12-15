{
  lib,
  user,
  policies,
  ...
}:
let
  app = "zsh";
  enable = policies.dev && lib.elem app user.shells;
in
{
  programs.${app} = {
    inherit enable;
  };
}
