{
  lib,
  lix,
  host,
  pkgs,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  # app = "kdenlive";
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
payload = {
    home.packages = with pkgs; [
      kdePackages.kdenlive
      shotcut
      darktable
      ansel
      doublecmd
      # davinci-resolve
    ];
  };
in {
config = lib.mkMerge (mkStaged{
    inherit top payload;
    condition = isAllowed;
  });
}
