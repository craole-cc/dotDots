{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "zeditor";
    kind = "editor";
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    name = "zed-editor";
    category = "gui";
    resolutionHints = [
      "zed-editor"
      "zeditor"
      "zed"
    ];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./theme.nix)
      # (import ./editor.nix)
      # (import ./keybindings.nix)
      # (import ./languages.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = resolved.enable;
    };
    outputs = {inherit (resolved) home programs;};
  }
