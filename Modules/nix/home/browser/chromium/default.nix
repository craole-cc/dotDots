{
  config,
  policies,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.strings) toUpper;
  inherit (lib.strings) match toJSON;
  inherit (policies) webGui;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "chromium";
  };

  name = "chromium";
  target = user.applications.browser.chromium or null;
  normalizedTarget =
    if target == null
    then "default"
    else target;

  matches = pred: str: str != null && match pred str != null;

  variant =
    #| Brave
    if matches "brave" target
    then "brave"
    #| Chrome
    else if matches "chrome" target
    then "google-chrome"
    #| Chromium
    else if normalizedTarget == "default" || matches "chromium" target || matches "ungoogled" target
    then "chromium"
    #| Vivaldi
    else if matches "viv" target
    then "vivaldi"
    else null;

  package =
    if variant != null
    then pkgs.${variant}
    else null;

  enable = webGui && variant != null;

  debug = {
    key = "_dbg_${toUpper name}";
    val = toJSON {
      criteria = {
        inherit webGui;
        targetRequested =
          if target == null
          then "undefined"
          else target;
        normalized = normalizedTarget;
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
