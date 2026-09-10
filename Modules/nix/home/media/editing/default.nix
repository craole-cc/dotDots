{
  config,
  lix,
  host,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "media";
    mod = "editing";
  };
  isAllowed = isIn "video" (host.functionalities or []);
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.home.packages = with pkgs; [
      kdePackages.kdenlive
      shotcut
      darktable
      ansel
      doublecmd
      # davinci-resolve
    ];
  }
