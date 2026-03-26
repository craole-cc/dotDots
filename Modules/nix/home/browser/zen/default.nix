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
  inherit (lib.modules) mkIf mkMerge mkForce;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.applications.utilities) mkScriptWrappers;
  inherit (lix.strings.transform) normalize;
  inherit (lix.strings.predicates) contains;

  apps = user.applications or {};
  firefox = normalize (apps.browser.firefox or "");
  primary = normalize (apps.browser.primary or "");
  variant =
    if (contains "twilight" firefox) || (contains "zen" firefox)
    then "twilight"
    else "beta";
  isPrimary = primary != "" && (primary == firefox || (contains "zen" primary));

  #~@ Script Wrappers
  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      # script = tree.store.lib.sh + "/applications/zen.sh";
      script = ./wrapper.sh;
    in {zen = script;};
  };

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "zen-browser";
    kind = "browser";
    # customCommand = "zen";
    resolutionHints = ["zen-browser" "zen" "zen twilight" "zen beta"];
    requiresWayland = false;
    extraPackages = wrappers;
    extraProgramConfig = mkForce {
      package = pkgs."zen-${variant}";
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
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs;
  };
}
