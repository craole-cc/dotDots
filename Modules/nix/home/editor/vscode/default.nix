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

  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.types.options) mkEnable;
  inherit (lib.modules) mkDefault;

  ext = import ./extensions.nix {inherit lib lix pkgs inputs;};

  appCfg = userApplicationConfig {
    inherit user pkgs config;
    name = "vscode";
    kind = "editor";
    category = "gui";
    resolutionHints = ["vscode-insiders" "code" "code-insiders"];
    requiresWayland = true;
    extraPackages = [pkgs.vscode-fhs];
    extraProgramConfig = {
      profiles.default = mkMerge [
        {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
        }
        (import ./bindings.nix {})
        (import ./editor.nix {inherit mkDefault;})
        (ext.mkExtensions cfg.withExtensions)
        (import ./files.nix {})
        (import ./git.nix {})
        (import ./global.nix {})
        (import ./languages.nix {})
        (import ./terminal.nix {inherit mkDefault;})
        (import ./theme.nix {inherit mkDefault;})
      ];
    };
    debug = false;
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable mod appCfg.enable;
    withExtensions = ext.options;
  };

  config = mkIf cfg.enable {inherit (appCfg) home programs;};
}
