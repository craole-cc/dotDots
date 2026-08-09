{
  lib,
  lix,
  host,
  pkgs,
  top,
  ...
}: let
  # app = "kdenlive";
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
in {
config = lib.mkMerge [
    (mkIf isAllowed {
    home.packages = with pkgs; [
      kdePackages.kdenlive
      shotcut
      darktable
      ansel
      doublecmd
      # davinci-resolve
    ];
  })
    {${top}.output = mkIf isAllowed {
    home.packages = with pkgs; [
      kdePackages.kdenlive
      shotcut
      darktable
      ansel
      doublecmd
      # davinci-resolve
    ];
  };}
  ];
}
