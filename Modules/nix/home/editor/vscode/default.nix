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
  inherit (lix.types.options) mkTrue mkFalse mkEnableOption;

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
        (import ./bindings.nix)
        (import ./editor.nix {inherit lib;})
        (import ./extensions.nix {inherit lib lix pkgs inputs cfg dom mod;})
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
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = appCfg.enable;};

    withExtensions = {
      ai = mkTrue "AI assistance extensions";
      appearance = mkTrue "Themes, icons and UI chrome extensions";
      decorations = mkTrue "Inline highlights, guides and visual aids";
      infrastructure = mkFalse "Docker, SQL, DevOps extensions";
      markup = mkTrue "Markdown, TOML, YAML, config format extensions";
      nix = mkTrue "Nix language and tooling extensions";
      productivity = mkTrue "Workflow, file management and utility extensions";
      scripting = mkTrue "Python, Nushell, PowerShell extensions";
      systems = mkTrue "Rust, shell and systems programming extensions";
      vcs = mkTrue "Git, jj and version control extensions";
      web = mkTrue "Web development extensions";
    };
  };

  config = mkIf cfg.enable {
    inherit (appCfg) home programs;
  };
}
