{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "helix";
    kind = "editor";
    category = "tty";
    resolutionHints = ["hx" "helix" "helix-editor"];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./editor.nix)
      (import ./keybindings.nix)
      (import ./languages.nix)
      (import ./themes.nix)
    ];
    debug = true;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) home programs;
  };
}
