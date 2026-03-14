{
  policies,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (policies) webGui;

  name = "chromium";
  target = user.applications.browser.chromium;

  variant =
    #| Brave
    if matches "brave"
    then "brave"
    #| Chrome
    else if matches "chrome"
    then "google-chrome"
    #| Chromium
    else if normalizedTarget == "default" || matches "chromium" || matches "ungoogled"
    then "chromium"
    #| Microsoft Edge
    # else if matches "edge" || matches "microsoft" || matches "ms"
    # then "microsoft-edge"
    #| Vivaldi
    else if matches "viv"
    then "vivaldi"
    else null;

  package =
    if variant != null
    then pkgs.${variant}
    else null;

  enable = webGui && variant != null;

  debug = {
    key = "_dbg_${toUpper name}";
    val =
      toPretty {
        allowPrettyValues = true;
        multiline = true;
      } {
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
