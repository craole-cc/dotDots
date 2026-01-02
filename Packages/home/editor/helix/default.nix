{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "helix";
    kind = "editor";
    category = "tty";
    resolutionHints = ["hx" "helix" "helix-editor"];
    requiresWayland = true;
    extraProgramConfig = {
      settings =
        {}
        // import ./editor.nix
        // import ./keybindings.nix
        // import ./themes.nix;
      languages = import ./languages.nix;
    };
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
