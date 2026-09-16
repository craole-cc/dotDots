{
  lix,
  # config,
  lib,
  user,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  app = "quickshell";
  inherit (lib.lists) elem;
  inherit (lib.modules) mkMerge;
  isAllowed = elem app (user.applications.allowed or []);
  payload = {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./settings.nix)
    ];
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = isAllowed;
  });
}
