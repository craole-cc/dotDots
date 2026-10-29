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
  inherit (lix.lists.access) elemAt length;
  inherit (lix.schema.packages) selectedPackages;

  context = mkContext {
    inherit config;
    dom = "browser";
    mod = "zen";
  };

  allowed = map normalize (selectedPackages user);
  selections = user.packages.browser or ((lix.schema.packages.resolve {record = user;}).browser or []);

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

  browsers = map maybeBrowser selections;
  browserAt = index:
    if index < length browsers
    then elemAt browsers index
    else null;
  primaryBrowser = browserAt 0;
  secondaryBrowser = browserAt 1;
  tertiaryBrowser = browserAt 2;
  allowedZen = builtins.filter isZen (
    builtins.filter
    (app: app != null)
    (map maybeBrowser allowed)
  );

  isPrimary = isZen primaryBrowser;
  isSecondary = isZen secondaryBrowser;
  isTertiary = isZen tertiaryBrowser;
  requestedZen = builtins.filter isZen browsers ++ allowedZen;
  selectedZen =
    if requestedZen != []
    then builtins.head requestedZen
    else null;

  enable = selectedZen != null;
  dmsEnabled = config.programs.dank-material-shell.enable or false;
  dmsZenCss = "${config.xdg.configHome}/dms/zen.css";
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
