{
  config,
  host,
  lix,
  nixosConfig,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.strings.transformation) normalize;
  inherit (lix.strings.predicates) contains;

  name = "Zen";
  opts = [
    "zen"
    "zen-twilight"
    "zen-beta"
    "twilight"
  ];
  apps = user.applications or {};
  allowed = normalize (apps.allowed or []);
  primary = normalize (apps.browser.primary or "");
  secondary = normalize (apps.browser.secondary or "");
  isPrimary = isIn opts primary;
  isSecondary = isIn opts secondary;
  isAllowed = isIn opts allowed;
  variant =
    if
      contains "twilight" (
        [
          primary
          secondary
        ]
        ++ allowed
      )
    then "twilight"
    else "beta";
  darwinName = "${name}-${variant}";
  pkgName = "zen-${variant}";

  enable = isPrimary || isSecondary || isAllowed;
in {
  config = mkIf enable {
    programs.zen-browser = {
      inherit enable name;
      darwinAppName = darwinName;
      wrappedPackageName = pkgName;
      package = pkgs."${pkgName}";
      setAsDefaultBrowser = isPrimary;
      enableGnomeExtensions = nixosConfig.services.desktopManager.gnome.enable;
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
          BROWSER = pkgName;
          BROWSER_PRI = pkgName;
        }
        else if isSecondary
        then {BROWSER_SEC = pkgName;}
        else {};
    };
  };
}
