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
  inherit (lix.modules.core.staging) mkStaged;
  dom = "editors";
  mod = "vscode";
  cfg = config.${top}.inputs.${dom}.${mod};

  inherit (lix.modules.construction) mkIf mkMerge mkDefault;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.options.construction) mkEnable;

  base = import ./base/default.nix {inherit lib mkDefault;};
  features = import ./features/default.nix {
    inherit
      lib
      lix
      inputs
      pkgs
      ;
  };

  appCfg = userApplicationConfig {
    inherit user pkgs config;
    name = "vscode";
    kind = "editor";
    category = "gui";
    customPackage = pkgs.vscode-fhs;
    resolutionHints = [
      "vscode-insiders"
      "code"
      "code-insiders"
    ];
    requiresWayland = true;
    extraPackages = [
      pkgs.vscode-fhs
      inputs.vscode-insiders.packages.${pkgs.system}.vscode-insiders
    ];
    extraProgramConfig = {
      profiles.default = mkMerge (
        [base] ++ map (name: features.features.${name} cfg.withExtensions.${name}) (attrNames features.options)
      );
    };
    debug = false;
  };
payload = {inherit (appCfg) home programs;};
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnable {
      description = mod;
      condition = appCfg.enable;
    };
    withExtensions = features.options;
  };

config = lib.mkMerge (mkStaged{
    inherit top payload;
    condition = cfg.enable;
  });
}
