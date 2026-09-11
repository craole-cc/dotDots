{
  config,
  host,
  lix,
  user,
  paths,
  ...
}: let
  inherit (lix.applications.registry) resolve;
  inherit (lix.debug.tracing) tryEval;
  inherit (lix.lists.access) head;
  inherit (lix.lists.selection) filter;
  inherit (lix.modules.construction) mkConfig mkContext mkForce mkMerge;
  inherit (lix.options.construction) mkEnable;
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
      result = tryEval (browser value);
    in
      if result.success
      then result.value
      else null;

  isZen = app: app != null && (app.family or "") == "zen";

  primaryBrowser = maybeBrowser primary;
  secondaryBrowser = maybeBrowser secondary;
  tertiaryBrowser = maybeBrowser tertiary;
  allowedZen = filter isZen (
    filter
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
    then head allowedZen
    else null;

  enable = selectedZen != null;
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
          BROWSER = mkForce selectedZen.exec;
          BROWSER_PRI = mkForce selectedZen.exec;
        }
        else if isSecondary
        then {BROWSER_SEC = mkForce selectedZen.exec;}
        else if isTertiary
        then {BROWSER_TER = mkForce selectedZen.exec;}
        else {};
    };
  }
