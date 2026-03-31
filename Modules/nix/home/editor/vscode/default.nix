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

  inherit (lix.modules.construction) mkIf mkMerge mkDefault;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.options.construction) mkEnable;

  base = import ./base/default.nix {inherit lib mkDefault;};
  features = import ./features/default.nix {inherit lib lix inputs pkgs;};

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
        (name: features.features.${name} cfg.withExtensions.${name})
        (attrNames features.options)
      );
    };
    debug = false;
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = mod;
      condition = appCfg.enable;
    };
    withExtensions = features.options;
  };

  config = mkIf cfg.enable {inherit (appCfg) home programs;};
}
