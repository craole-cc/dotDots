{
  config,
  lib,
  lix,
  user,
  pkgs,
  top,
  ...
}: let
  inherit (lix.modules.core._) mkStaged;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "helix";
    kind = "editor";
    category = "tty";
    resolutionHints = [
      "hx"
      "helix"
      "helix-editor"
    ];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./editor.nix)
      (import ./keybindings.nix)
      (import ./languages.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
payload = {inherit (cfg) home programs;};
in {
config = lib.mkMerge (mkStaged{
    inherit top payload;
    condition = cfg.enable;
  });
}
