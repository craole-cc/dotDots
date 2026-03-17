{
  config,
  lib,
  lix,
  inputs,
  pkgs,
  top,
  user,
  ...
}: let
  dom = "editors";
  mod = "vscode";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.attrsets) attrNames;
  inherit (lib.modules) mkIf mkMerge mkDefault;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.types.options) mkEnable;

  base = import ./base {inherit lib mkDefault;};
  features = import ./features {inherit lib lix pkgs inputs;};

  appCfg = userApplicationConfig {
    inherit user pkgs config;
    name = "vscode";
    kind = "editor";
    category = "gui";
    resolutionHints = ["vscode-insiders" "code" "code-insiders"];
    requiresWayland = true;
    extraPackages = [pkgs.vscode-fhs];
    extraProgramConfig = {
      profiles.default = mkMerge (
        [base]
        ++ map
        (name: features.${name}.mkFeature cfg.withExtensions.${name})
        (attrNames features.options)
      );
    };
    debug = false;
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable mod appCfg.enable;
    withExtensions = features.options;
  };

  config = mkIf cfg.enable {inherit (appCfg) home programs;};
}
