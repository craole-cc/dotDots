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
  primary = normalize (apps.browser.primary or "");
  secondary = normalize (apps.browser.secondary or "");
  isPrimary = primary != "" && (contains "zen" primary);
  isSecondary = secondary != "" && (contains "zen" secondary);
  variant =
    if contains "twilight" [primary secondary]
    then "twilight"
    else "beta";

  #~@ Script Wrappers
  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      # script = tree.store.lib.sh + "/applications/zen.sh";
      script = ./wrapper.sh;
    in {zen = script;};
  };

  enable = isPrimary || isSecondary;

  programs.zen-browser = {
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
  home.packages = [wrappers];

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
  config = mkIf enable {
    inherit enable programs home;
  };
}
