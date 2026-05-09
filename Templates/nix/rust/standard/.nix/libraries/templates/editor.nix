{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkPkgs;
  inherit (lib.shells) mkDeployConfig setSource;
  inherit (lib.strings) mkStyledOutput;

  mkSource = group: name: setSource ["editor" group name];
  mkEntry = group: name: {
    source = mkSource group name;
    target = ".${group}/${name}";
  };

  entries = {
    editorconfig = {
      base = {
        source = setSource ["editor" "editorconfig"];
        target = ".editorconfig";
      };
    };

    vscode = {
      settings = mkEntry "vscode" "settings.json";
      extensions = mkEntry "vscode" "extensions.json";
      tasks = mkEntry "vscode" "tasks.json";
      launch = mkEntry "vscode" "launch.json";
    };

    helix = {
      config = mkEntry "helix" "config.toml";
      languages = mkEntry "helix" "languages.toml";
    };

    zed = {
      settings = mkEntry "zed" "settings.json";
      tasks = mkEntry "zed" "tasks.json";
    };

    rust-rover = {
      rust = mkEntry "idea" "rust.xml";
      misc = mkEntry "idea" "misc.xml";
      cargo-run = mkEntry "idea" "runConfigurations/cargo.xml";
      cargo-test = mkEntry "idea" "runConfigurations/tests.xml";
    };

    neovim = {
      neoconf = {
        source = mkSource "neovim" "neoconf.json";
        target = ".neoconf.json";
      };
      config = {
        source = mkSource "neovim" "nvim.lua";
        target = ".nvim.lua";
      };
    };
  };

  deployConfig = {
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    includeFormat ? true,
    editor ? null,
  }:
    mkDeployConfig {
      inherit pkgs print includeFormat;
      title = "Editor Configuration Deployment";
      description = "Syncing project editor configuration files into your workspace";
      extraEntries =
        optionalAttrs (editor != null && editor != "none")
        (
          entries.editorconfig
          // optionalAttrs (editor == "vscode") entries.vscode
          // optionalAttrs (editor == "helix") entries.helix
          // optionalAttrs (editor == "zed") entries.zed
          // optionalAttrs (editor == "rustrover") entries.rustrover
          // optionalAttrs (editor == "neovim") entries.neovim
        );
    };
in {
  inherit entries deployConfig;
}
