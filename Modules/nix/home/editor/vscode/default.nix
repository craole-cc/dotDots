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

  # Resolve the existing profile fragments through a small option module so
  # mkDefault/mkMerge semantics are preserved without making stable VS Code's
  # writable user configuration Home Manager-owned.
  jsonFormat = pkgs.formats.json {};
  profile =
    (lib.evalModules {
      modules = [
        {
          options = {
            userSettings = lib.mkOption {
              type = jsonFormat.type;
              default = {};
            };
            keybindings = lib.mkOption {
              type = lib.types.listOf jsonFormat.type;
              default = [];
            };
            extensions = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [];
            };
          };
        }
        {
          config = mkMerge (
            [base]
            ++ map (name: features.features.${name} cfg.withExtensions.${name}) (attrNames features.options)
          );
        }
      ];
    }).config;

  system = pkgs.stdenv.hostPlatform.system;
  insidersBase = inputs.vscode-insiders.packages.${system}.vscode-insiders;
  insiders = pkgs.vscode-with-extensions.override {
    vscode = insidersBase;
    vscodeExtensions = profile.extensions;
  };

  # Stable VS Code is deliberately mutable: install the FHS package, but do
  # not enable Home Manager's programs.vscode profile/file management. Insiders
  # is the declarative editor and gets the managed settings + extension set.
  resolved = userApplicationConfig {
    inherit context user pkgs;
    name = "vscode";
    category = "gui";
    customPackage = pkgs.vscode-fhs;
    resolutionHints = [
      "code"
      "vscode"
    ];
    requiresWayland = true;
    extraPackages = [insiders];
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
    outputs = {
      inherit (resolved) home;

      xdg.configFile = {
        "Code - Insiders/User/settings.json".source =
          jsonFormat.generate "vscode-insiders-settings.json" profile.userSettings;
        "Code - Insiders/User/keybindings.json".source =
          jsonFormat.generate "vscode-insiders-keybindings.json" profile.keybindings;
      };
    };
  }
