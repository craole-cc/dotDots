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
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.applications.utilities) mkScriptWrappers;

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
    customCommand = "feet";
    resolutionHints = ["zen-browser" "zen" "zen twilight" "zen beta"];
    requiresWayland = true;
    extraPackages = wrappers;
    extraProgramConfig = {
      profiles.${user.name} = mkMerge [
        (import ./bookmarks.nix)
        (import ./containers.nix)
        (import ./search.nix {inherit host;})
      ];
      policies = mkMerge [
        (import ./policies.nix {inherit lix;})
        (import ./extensions.nix {inherit lix;})
      ];
    };
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
