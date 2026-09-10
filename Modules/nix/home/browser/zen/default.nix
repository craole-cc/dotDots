{
  config,
  host,
  inputs,
  lix,
  pkgs,
  user,
  paths,
  lib,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext mkMerge;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.applications.registry) resolve;
  inherit (lix.applications.runtime) resolvePackage;
  inherit (lix.strings.transformation) normalize;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "zen";
  };

  name = "Zen";
  apps = user.applications or {};
  allowed = normalize (apps.allowed or []);
  primary = normalize (apps.browser.primary or "");
  secondary = normalize (apps.browser.secondary or "");
  tertiary = normalize (apps.browser.tertiary or "");
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
  isTertiary = isZen tertiary;
  isAllowed = builtins.any isZen allowed;
  variant = twilight.package.attribute;
  darwinName = "${name}-${variant}";
  system = pkgs.stdenv.hostPlatform.system;
  package = resolvePackage {
    app = twilight;
    inherit inputs pkgs system;
  };

  enable = isPrimary || isSecondary || isTertiary || isAllowed;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = enable;
    };
    outputs = {
      programs.zen-browser = {
        enable = true;
        inherit name package;
        darwinAppName = darwinName;
        wrappedPackageName = variant;
        setAsDefaultBrowser = isPrimary;
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

      home.sessionVariables =
        if isPrimary
        then {
          BROWSER = lib.mkForce twilight.exec;
          BROWSER_PRI = lib.mkForce twilight.exec;
        }
        else if isSecondary
        then {BROWSER_SEC = lib.mkForce twilight.exec;}
        else if isTertiary
        then {BROWSER_TER = lib.mkForce twilight.exec;}
        else {};
    };
  }
