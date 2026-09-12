{
  config,
  host,
  lix,
  user,
  paths,
  lib,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext mkMerge;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.applications.registry) resolve;
  inherit (lix.strings.transformation) normalize;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "zen";
  };

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

  maybeBrowser = value:
    if value == null || value == ""
    then null
    else let
      result = builtins.tryEval (browser value);
    in
      if result.success
      then result.value
      else null;

  isZen = app: app != null && (app.family or "") == "zen";

  primaryBrowser = maybeBrowser primary;
  secondaryBrowser = maybeBrowser secondary;
  tertiaryBrowser = maybeBrowser tertiary;
  allowedZen = builtins.filter isZen (
    builtins.filter
    (app: app != null)
    (map maybeBrowser allowed)
  );

  isPrimary = isZen primaryBrowser;
  isSecondary = isZen secondaryBrowser;
  isTertiary = isZen tertiaryBrowser;
  selectedZen =
    if isPrimary
    then primaryBrowser
    else if isSecondary
    then secondaryBrowser
    else if isTertiary
    then tertiaryBrowser
    else if allowedZen != []
    then builtins.head allowedZen
    else null;

  enable = selectedZen != null;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  dmsZenCss = "${config.xdg.configHome}/DankMaterialShell/zen.css";
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
        setAsDefaultBrowser = isPrimary;
        profiles.${user.name} = mkMerge [
          (
            if dmsEnabled
            then {
              # DMS's native Zen Matugen template writes this file. Keep the
              # profile declarative and import the mutable generated palette
              # rather than duplicating DMS colors in Nix.
              userChrome = ''
                @import url("file://${dmsZenCss}");
              '';
            }
            else {}
          )
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
          BROWSER = lib.mkForce selectedZen.exec;
          BROWSER_PRI = lib.mkForce selectedZen.exec;
        }
        else if isSecondary
        then {BROWSER_SEC = lib.mkForce selectedZen.exec;}
        else if isTertiary
        then {BROWSER_TER = lib.mkForce selectedZen.exec;}
        else {};
    };
  }
