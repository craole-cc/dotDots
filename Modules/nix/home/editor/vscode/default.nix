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
  inherit (lib.options) mkEnableOption;
  inherit (lix.applications.generators) userApplicationConfig;

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
        (import ./extensions.nix {inherit lib lix pkgs inputs cfg;})
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

  mkGroupOption = description:
    mkEnableOption description // {default = true;};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = appCfg.enable;};

    withExtensions = {
      ai = mkGroupOption "AI assistance extensions";
      appearance = mkGroupOption "Themes, icons and UI chrome extensions";
      decorations = mkGroupOption "Inline highlights, guides and visual aids";
      infrastructure = mkGroupOption "Docker, SQL, DevOps extensions";
      markup = mkGroupOption "Markdown, TOML, YAML, config format extensions";
      nix = mkGroupOption "Nix language and tooling extensions";
      productivity = mkGroupOption "Workflow, file management and utility extensions";
      scripting = mkGroupOption "Python, Nushell, PowerShell extensions";
      systems = mkGroupOption "Rust, shell and systems programming extensions";
      vcs = mkGroupOption "Git, jj and version control extensions";
      web = mkGroupOption "Web development extensions";
    };
  };

  config = mkIf cfg.enable {
    inherit (appCfg) home programs;
  };
}
