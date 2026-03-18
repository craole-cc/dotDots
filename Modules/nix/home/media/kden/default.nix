{
  lib,
  lix,
  host,
  pkgs,
  ...
}: let
  # app = "kdenlive";
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
in {
  config = mkIf isAllowed {
    home.packages = with pkgs; [kdePackages.kdenlive];
  };
}
