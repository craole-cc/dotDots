{
  policies,
  lib,
  user,
  pkgs,
  ...
}: let
  inherit (lib.strings) toUpper;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) match toJSON;
  inherit (policies) webGui;

  name = "chromium";
  target = user.applications.browser.chromium;
  normalizedTarget =
    if target == null
    then "default"
    else target;

  matches = pred: str: match pred str != null;

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
    #| Microsoft Edge
    else if matches "edge" target || matches "microsoft" target || matches "ms" target
    then "microsoft-edge"
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
in {
  programs.chromium = mkIf enable {
    inherit enable package;
  };

  home.sessionVariables = optionalAttrs enable {
    ${debug.key} = debug.val;
  };
}
