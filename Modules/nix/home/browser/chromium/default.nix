{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.strings) match toJSON toUpper;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "chromium";
  };

  name = "chromium";
  target = user.applications.browser.chromium or null;

  matches = pred: str: str != null && match pred str != null;

  variant =
    if target == null
    then null
    #| Brave
    else if matches "brave" target
    then "brave"
    #| Chrome
    else if matches "chrome" target
    then "google-chrome"
    #| Chromium
    else if target == "default" || matches "chromium" target || matches "ungoogled" target
    then "chromium"
    #| Vivaldi
    else if matches "viv" target
    then "vivaldi"
    else null;

  package =
    if variant != null
    then pkgs.${variant}
    else null;

  enable = variant != null;

  debug = {
    key = "_dbg_${toUpper name}";
    val = toJSON {
      criteria = {
        targetRequested =
          if target == null
          then "undefined"
          else target;
        valid = enable;
      };
      resolved = {
        variant =
          if variant != null
          then variant
          else "none";
        packageName =
          if package != null
          then package.name
          else "none";
      };
    };
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = enable;
    };
    outputs = {
      programs.chromium = {
        enable = true;
        inherit package;
      };
      home.sessionVariables.${debug.key} = debug.val;
    };
  }
