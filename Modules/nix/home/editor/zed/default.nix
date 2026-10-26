{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "zeditor"; # TODO Change this and the folder name to zed
    kind = "editor";
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    name = "zed-editor";
    category = "gui";
    customPackage =
      if isIn "zed-editor-fhs" (user.applications.allowed or [])
      then pkgs.zed-editor-fhs
      else pkgs.zed-editor;
    resolutionHints = [
      "zed-editor"
      "zed-editor-fhs"
      "zeditor"
      "zed"
    ];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./theme.nix {inherit lix;})
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
