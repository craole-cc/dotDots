{
  # config,
  lib,
  user,
  top,
  ...
}: let
  app = "quickshell";
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf mkMerge;
  isAllowed = elem app (user.applications.allowed or []);
in {
config = lib.mkMerge [
    (mkIf isAllowed {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./settings.nix)
    ];
  })
    {${top}.output = mkIf isAllowed {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./settings.nix)
    ];
  };}
  ];
}
