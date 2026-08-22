{
  host,
  inputs,
  lix,
  nixosConfig,
  pkgs,
  user,
  paths,
  lib,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lix.modules.construction) mkMerge;
  inherit (lix.applications.registry) resolve;
  inherit (lix.applications.runtime) resolvePackage;
  inherit (lix.strings.transformation) normalize;

  name = "Zen";
  apps = user.applications or {};
  allowed = normalize (apps.allowed or []);
  primary = normalize (apps.browser.primary or "");
  secondary = normalize (apps.browser.secondary or "");
  browser = value:
    resolve {
      inherit value;
      category = "browser";
    };
  twilight = resolve {
    value = "zen-twilight";
    category = "browser";
  };
  isZen = value: value != "" && (browser value).family == "zen";
  isPrimary = isZen primary;
  isSecondary = isZen secondary;
  isAllowed = builtins.any isZen allowed;
  variant = twilight.package.attribute;
  darwinName = "${name}-${variant}";
  package = resolvePackage {
    app = twilight;
    inherit inputs pkgs;
    inherit (pkgs) system;
  };

  enable = isPrimary || isSecondary || isAllowed;
  payload = {
    programs.zen-browser = {
      inherit enable name;
      darwinAppName = darwinName;
      wrappedPackageName = variant;
      inherit package;
      setAsDefaultBrowser = isPrimary;
      enableGnomeExtensions = nixosConfig.services.desktopManager.gnome.enable;
      profiles.${user.name} = mkMerge [
        (import ./bookmarks.nix)
        (import ./containers.nix)
        (import ./search.nix {inherit host;})
        (import ./settings.nix)
      ];
      policies = mkMerge [
        (import ./policies.nix {inherit paths;})
        (import ./extensions.nix {inherit lix;})
        (import ./preferences.nix {inherit lix;})
      ];
    };

    home = {
      sessionVariables =
        if isPrimary
        then {
          BROWSER = lib.mkForce "zen";
          BROWSER_PRI = lib.mkForce "zen";
        }
        else if isSecondary
        then {BROWSER_SEC = lib.mkForce "zen";}
        else {};
    };
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = enable;
  });
}
