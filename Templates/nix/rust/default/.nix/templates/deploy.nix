{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatStringsSep escapeShellArg mkHeader mkSection mkStyledOutput replaceStrings;
  inherit (lib.trivial) readFile;
  inherit (paths) config;

  scripts.deployConf = ./deploy.sh;

  # The flake/config anchor. This should resolve to ./.nix.
  # Runtime reset/deploy scripts should use the nearest `.nix` directory
  # to decide the active project root.
  anchor = paths.nix;

  entries = {
    base = {
      envrc = {
        source = config + "/envrc";
        target = ".envrc";
      };

      gitignore = {
        source = config + "/gitignore";
        target = ".gitignore";
      };

      shellcheck = {
        source = config + "/shellcheckrc";
        target = [".shellcheckrc" "shellcheckrc"];
      };
    };

    rust = {
      cargo = {
        source = config + "/cargo.toml";
        target = ".cargo/config.toml";
      };

      rust-analyzer = {
        source = config + "/rust-analyzer.toml";
        target = [".rust-analyzer.toml" "rust-analyzer.toml"];
      };

      rust-toolchain = {
        source = config + "/rust-toolchain.toml";
        target = "rust-toolchain.toml";
      };

      rustfmt = {
        source = config + "/rustfmt.toml";
        target = [".rustfmt.toml" "rustfmt.toml"];
      };
    };

    web = {
      deno = {
        source = config + "/deno.jsonc";
        target = "deno.jsonc";
      };

      prettier = {
        source = config + "/prettierrc";
        target = [".prettierrc" "prettier.config.json"];
      };

      trunk = {
        source = config + "/trunk.toml";
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

    format = {
      markdownlint = {
        source = config + "/markdownlint-cli2.yaml";
        target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
      };

      treefmt = {
        source = config + "/treefmt.toml";
        target = [".treefmt.toml" "treefmt.toml"];
      };
    };

    editor = {};
  };

  deployEntry = name: {
    source,
    target,
  }: let
    targets = toList target;
    preferred = head targets;
    quotedTargets =
      concatStringsSep " "
      (map escapeShellArg targets);
  in ''
    deploy_entry ${
      escapeShellArg name
    } ${
      escapeShellArg (toString source)
    } ${
      escapeShellArg preferred
    } ${quotedTargets} || status=1
  '';

  deployConfig = {
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    includeRust ? true,
    includeWeb ? false,
    includeEditor ? false,
    includeFormat ? true,
  }: let
    selected = with entries;
      base
      // optionalAttrs includeRust rust
      // optionalAttrs includeWeb web
      // optionalAttrs includeFormat format
      // optionalAttrs includeEditor editor;

    content = ''
      ${mkHeader {
        inherit print;
        title = "Configuration Deployment";
        content = "Syncing project configuration files into your workspace";
      }}
      ${mkSection {
        inherit print;
        title = "Entries";
        content = map (name: name) (attrNames selected);
      }}
      status=0
      ${
        concatStringsSep "\n" (
          map
          (name: deployEntry name selected.${name})
          (attrNames selected)
        )
      }
      return "''${status}"
    '';

    source =
      replaceStrings
      ["#__DEPLOY_CONF_CALLS__"]
      [content]
      (readFile scripts.deployConf);
  in
    pkgs.writeShellScriptBin "deploy-conf" source;
in {
  inherit
    anchor
    entries
    # scripts
    deployConfig
    ;
}
