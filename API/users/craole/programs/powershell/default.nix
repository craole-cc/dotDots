{
  pkgs,
  lib,
  user,
  policies,
  ...
}:
let
  app = "powershell";
  enable = policies.dev && lib.elem app user.shells;
in
{
  home.packages = lib.mkIf enable (
    with pkgs;
    [
      powershell
      powershell-editor-services
    ]
  );
}
