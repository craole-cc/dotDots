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

  mkGroupOption = name: description:
    mkEnableOption description // {default = true;};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = appCfg.enable;};

    extensions = {
      vcs = mkGroupOption "vcs" "Git, jj and version control extensions";
      ai = mkGroupOption "ai" "AI assistance extensions";
      nix = mkGroupOption "nix" "Nix language and tooling extensions";
      systems = mkGroupOption "systems" "Rust, shell and systems programming extensions";
      scripting = mkGroupOption "scripting" "Python, Nushell, PowerShell extensions";
      web = mkGroupOption "web" "Web development extensions";
      markup = mkGroupOption "markup" "Markdown, TOML, YAML, config format extensions";
      infrastructure = mkGroupOption "infrastructure" "Docker, SQL, DevOps extensions";
      appearance = mkGroupOption "appearance" "Themes, icons and UI chrome extensions";
      decorations = mkGroupOption "decorations" "Inline highlights, guides and visual aids";
      productivity = mkGroupOption "productivity" "Workflow, file management and utility extensions";
    };
  };

  config = mkIf cfg.enable {
    inherit (appCfg) home programs;
  };
}
