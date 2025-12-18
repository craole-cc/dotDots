{
  pkgs,
  lib,
  user,
  ...
}: let
  app = "powershell";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed || elem app user.shells;
in {
  home.packages = lib.mkIf isAllowed (
    with pkgs; [
      powershell
      powershell-editor-services
    ]
  );
}
