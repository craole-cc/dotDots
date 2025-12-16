{
  pkgs,
  lib,
  user,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "powershell";
  isAllowed = elem app enable || elem app user.shells;
in {
  home.packages = lib.mkIf isAllowed (
    with pkgs; [
      powershell
      powershell-editor-services
    ]
  );
}
