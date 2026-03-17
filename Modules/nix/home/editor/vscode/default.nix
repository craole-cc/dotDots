{
  config,
  lib,
  lix,
  inputs,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
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
        (import ./bindings.nix)
        (import ./editor.nix {inherit lib;})
        (import ./extensions.nix {inherit lib lix pkgs inputs;})
        (import ./files.nix)
        (import ./git.nix)
        (import ./global.nix)
        (import ./languages.nix)
        (import ./terminal.nix)
        (import ./theme.nix)
      ];
    };
    debug = false;
  };
in {
  config = mkIf cfg.enable {inherit (cfg) home programs;};
}
