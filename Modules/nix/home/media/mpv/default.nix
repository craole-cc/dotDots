{
  config,
  lib,
  lix,
  host,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "media";
    mod = "mpv";
  };
  isAllowed = isIn "video" (host.functionalities or []);
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs = {
      programs.mpv = mkMerge [
        {enable = true;}
        (import ./bindings.nix)
        (import ./settings.nix {inherit pkgs;})
      ];
      home.packages = with pkgs; [ffmpeg-full];
    };
  }
