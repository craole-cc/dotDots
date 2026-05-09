{lib}: let
  inherit (lib.shells) mkShells mkVariants;

  # deployConfig = {
  #   pkgs ? mkPkgs {},
  #   includeAI ? true,
  #   includeBase ? true,
  #   includeFormat ? true,
  #   includeRust ? true,
  #   includeWeb ? false,
  #   style ? mkStyledOutput {inherit pkgs;},
  #   withEditor ? null,
  # }: let
  #   templates =
  #     optionalAttrs includeBase (common.base.templates or {})
  #     // optionalAttrs includeFormat (common.format.templates or {})
  #     // optionalAttrs includeAI (ai.templates or {})
  #     // optionalAttrs includeRust (rust.entries.rust or {})
  #     // optionalAttrs includeWeb (web.templates or {})
  #     // (
  #       optionalAttrs
  #       (withEditor != null && withEditor != "none")
  #       (editor.entries.common // editor.entries."${withEditor}")
  #     );
  # in
  #   mkDeployConfig {
  #     inherit pkgs style templates;
  #     title = "Configuration Deployment";
  #     description = "Syncing project configuration files into your workspace";
  #   };

  mkEnvironment = {
    inputs,
    pkgs,
    self,
  }: let
    variants = mkVariants {
      inherit pkgs inputs self;
      variants = {
        minimal = {};
        default = {includeExtras = true;};
        stable = {
          channel = "stable";
          includeExtras = true;
        };
        full = {
          includeExtras = true;
          includeWeb = true;
          includeDatabase = true;
          includeRust = true;
        };
      };
      editors = [
        "helix"
        "emacs"
        "neovim"
        "rust-rover"
        "sublime-text"
        "vscode"
        "vscode-insiders"
        "zed"
      ];
    };
    # namespaced = (mergeNamespaces {inherit rust ai;}).mkDevShell {inherit pkgs;};
  in {
    devShells = mkShells {
      inherit inputs;
      default = variants.shells.minimal;
      # shells = namespaced // variants.shells;
      inherit (variants) shells;
    };
    checks = variants.checks;
    fmt = variants.fmts.default;
  };
in {inherit mkEnvironment;}
