{
  config,
  lib,
  lix,
  user,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "zed-editor";
    kind = "editor";
    category = "gui";
    resolutionHints = [
      "zeditor"
      "zed-editor"
    ];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      # (import ./editor.nix)
      # (import ./keybindings.nix)
      # (import ./languages.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
in {
config = lib.mkMerge [
    (mkIf cfg.enable {inherit (cfg) home programs;})
    {${top}.output = mkIf cfg.enable {inherit (cfg) home programs;};}
  ];
}
