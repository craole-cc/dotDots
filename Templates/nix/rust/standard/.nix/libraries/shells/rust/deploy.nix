{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) mkStyledOutput;
  inherit (lib.shells) mkDeployConfig setSource;

  entries = {
    rust = let
      mkSrc = name: setSource ["rust" name];
    in {
      cargo = {
        source = mkSrc "cargo.toml";
        target = ".cargo/config.toml";
      };
      rust-analyzer = {
        source = mkSrc "rust-analyzer.toml";
        target = [".rust-analyzer.toml" "rust-analyzer.toml"];
      };
      rust-toolchain = {
        source = mkSrc "rust-toolchain.toml";
        target = "rust-toolchain.toml";
      };
      rustfmt = {
        source = mkSrc "rustfmt.toml";
        target = [".rustfmt.toml" "rustfmt.toml"];
      };
    };

    web = let
      mkSrc = name: setSource ["rust" name];
    in {
      deno = {
        source = mkSrc "deno.jsonc";
        target = "deno.jsonc";
      };
      prettier = {
        source = mkSrc "prettierrc";
        target = [".prettierrc" "prettier.config.json"];
      };
      trunk = {
        source = mkSrc "trunk.toml";
        target = [
          ".trunk.toml"
          "Trunk.toml"
          ".trunk.yaml"
          "Trunk.yaml"
          ".trunk.json"
          "Trunk.json"
        ];
      };
    };
  };

  deployConfig = {
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    includeWeb ? false,
    includeFormat ? true,
    includeEditor ? false,
  }:
    mkDeployConfig {
      inherit pkgs print includeFormat includeEditor;
      title = "Rust Configuration Deployment";
      description = "Syncing Rust project configuration files into your workspace";
      extraEntries = entries.rust // optionalAttrs includeWeb entries.web;
    };
in {
  inherit entries deployConfig;
}
