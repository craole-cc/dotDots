{
  config,
  lib,
  lix,
  inputs,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkDefault;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "vscode";
    kind = "editor";
  };
  inherit (context) cfg;

  base = import ./base/default.nix {inherit lib mkDefault;};
  features = import ./features/default.nix {
    inherit
      lib
      lix
      inputs
      pkgs
      ;
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    name = "vscode";
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
        [base]
        ++ map (name: features.features.${name} cfg.withExtensions.${name}) (attrNames features.options)
      );
    };
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = resolved.enable;
      };
      withExtensions = features.options;
    };
    outputs = {inherit (resolved) home programs;};
  }
