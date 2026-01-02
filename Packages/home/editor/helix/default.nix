{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.applications.generators) userApplicationConfig userApplication;

  #~@ Application Configuration
  app = userApplication {
    inherit user pkgs config;
    name = "helix";
    kind = "editor";
    category = "tty";
    resolutionHints = ["hx" "helix" "helix-editor"];
    requiresWayland = true;
  };

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraProgramConfig =
      {defaultEditor = app.isPrimary;}
      // import ./editor.nix
      // import ./keybindings.nix
      // import ./languages.nix
      // import ./themes.nix
      // {};
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
