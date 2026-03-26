{
  config,
  lib,
  host,
  lix,
  user,
  pkgs,
  # tree,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.strings.transform) normalize;
  inherit (lix.strings.predicates) contains;

  browser = user.applications.browser or {};
  primary = normalize (browser.primary or "");
  secondary = normalize (browser.secondary or "");
  isPrimary = primary != "" && (contains "zen" primary);
  isSecondary = secondary != "" && (contains "zen" secondary);
  variant =
    if contains "twilight" [primary secondary]
    then "twilight"
    else "beta";
  name = "zen-${variant}";
  enable = isPrimary || isSecondary;
in {
  config = mkIf enable {
    programs.zen-browser = {
      inherit enable;
      package = pkgs."${name}";
      setAsDefaultBrowser = isPrimary;
      profiles.${user.name} = mkMerge [
        (import ./bookmarks.nix)
        (import ./containers.nix)
        (import ./search.nix {inherit host;})
        (import ./settings.nix)
      ];
      policies = mkMerge [
        (import ./policies.nix {inherit config;})
        (import ./extensions.nix {inherit lix;})
        (import ./preferences.nix {inherit lix;})
      ];
    };

    home = {
      sessionVariables =
        if isPrimary
        then {
          BROWSER = name;
          BROWSER_PRI = name;
        }
        else if isSecondary
        then {BROWSER_SEC = name;}
        else {};
    };
  };
}
