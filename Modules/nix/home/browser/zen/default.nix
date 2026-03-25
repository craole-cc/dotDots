{
  lib,
  lix,
  user,
  config,
  pkgs,
  tree,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.utilities) mkScriptWrapper;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "zen";
    kind = "browser";
    resolutionHints = ["zen-browser" "zen-twilight"];
    extraProgramConfig = mkMerge [
      # (import ./editor.nix)
      # (import ./keybindings.nix)
      # (import ./languages.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
  # launcher = mkScriptWrapper {
  #   inherit pkgs;
  #   name = "zen";
  #   # script = ./wrapper.sh;
  #   script = tree.store.lib.sh + "/applications/zen.sh";
  # };
in {
  config = mkIf cfg.enable {
    inherit (cfg) home programs;
  };
}
