{
  # user,
  lib,
  lix,
  host,
  pkgs,
  ...
}: let
  app = "mpv";
  inherit (lib.modules) mkMerge;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
in {
  programs.${app} = mkMerge [
    {enable = isAllowed;}
    (import ./bindings.nix)
    (import ./settings.nix {inherit pkgs;})
  ];
  home.packages = with pkgs; [ffmpeg-full];
}
