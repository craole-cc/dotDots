{lib, ...}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head last toList optional;
  inherit (lib.packages) mkPkgs;
  inherit
    (lib.strings)
    concatNonEmpty
    concatStringsSep
    escapeShellArg
    mkHeader
    mkSection
    mkStyledOutput
    replaceStrings
    toLines
    hasSuffix
    toPathString
    ;
  inherit (lib.trivial) readFile;
  inherit (lib.shells) rust ai editor setMarker setSource;
  esc = escapeShellArg;
  anchor = setMarker {};
  project = baseNameOf anchor;

  deployTemplate = name: {
    source,
    target,
  }: let
    targetList = toList target;
    label = esc name;
    path = esc (toString source);
    targets = {
      preferred = esc (head targetList);
      quoted = concatNonEmpty {
        separator = " ";
        parts = map esc targetList;
      };
    };
  in
    with targets; ''
      deploy_entry ${label} ${path} ${preferred} ${quoted} || status=1
    '';

  mkDeployConfig = {
    title ? "Configuration Deployment",
    description ? "Syncing project configuration files into your workspace",
    templates ? {},
    pkgs ? mkPkgs {},
    style ? mkStyledOutput {inherit pkgs;},
  }: let
    content = ''
      ${mkHeader {
        inherit style title;
        content = description;
      }}
      ${mkSection {
        inherit style;
        title = "Entries";
        content = attrNames templates;
      }}
      status=0
      ${concatNonEmpty {
        separator = "\n";
        parts = map (n: deployTemplate n templates.${n}) (attrNames templates);
      }}
      return "''${status}"
    '';

    source =
      replaceStrings ["#__DEPLOY_CONF_CALLS__"] [content]
      (readFile ./deploy.sh);
  in
    pkgs.writeShellScriptBin "deploy-config" source;

  getTemplates = {
    pkgs,
    projectName ? project,
    includeBase ? true,
    includeFormat ? true,
    includeAI ? true,
    includeRust ? true,
    includeWeb ? false,
    withEditor ? null,
  }: let
    all = {
      base = {
        envrc = {
          source = setSource ["base" "envrc"];
          target = ".envrc";
        };
        gitignore = {
          source = setSource ["base" "gitignore"];
          target = ".gitignore";
        };
        mise = {
          source = setSource ["base" "mise"];
          target = [".mise.toml" "mise.toml"];
        };
        shellcheck = {
          source = setSource ["base" "shellcheckrc"];
          target = [".shellcheckrc" "shellcheckrc"];
        };
      };
      format = {
        markdownlint = {
          source = setSource ["base" "markdownlint-cli2.yaml"];
          target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
        };
        treefmt = {
          source = setSource ["base" "treefmt.toml"];
          target = [".treefmt.toml" "treefmt.toml"];
        };
      };
      rust = {
        cargo = {
          source = setSource ["rust" "cargo.toml"];
          target = ".cargo/config.toml";
        };
        rust-analyzer = {
          source = setSource ["rust" "rust-analyzer.toml"];
          target = [".rust-analyzer.toml" "rust-analyzer.toml"];
        };
        rust-toolchain = {
          source = setSource ["rust" "rust-toolchain.toml"];
          target = "rust-toolchain.toml";
        };
        rustfmt = {
          source = setSource ["rust" "rustfmt.toml"];
          target = [".rustfmt.toml" "rustfmt.toml"];
        };
      };
      web = {
        deno = {
          source = setSource ["web" "deno.jsonc"];
          target = "deno.jsonc";
        };
        prettier = {
          source = setSource ["web" "prettierrc"];
          target = [".prettierrc" "prettier.config.json"];
        };
        trunk = {
          source = setSource ["web" "trunk.toml"];
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
      ai = {};
      editor = let
        base = "editor";
        mkSource = stems: setSource [base stems];
        mkTarget = stems: ".${toPathString stems}";
        mkEntry = stems: let
          stem = toPathString stems;
        in {
          # If the file is 'modules.xml' or '.iml', process it. Otherwise, leave it.
          source =
            if (hasSuffix "modules.xml" stem) || (hasSuffix ".iml" stem)
            then
              pkgs.runCommand "processed-${concatStringsSep "-" stem}" {} ''
                substitute ${esc (toString (mkSource stem))} $out \
                  --replace-fail "PROJECT_NAME" ${esc projectName}
              ''
            else mkSource stem;
          target = mkTarget stem;
        };
      in {
        common = {
          editorconfig = {
            source = mkSource ["common" "editorconfig"];
            target = mkTarget "editorconfig";
          };
        };

        vscode = {
          settings = mkEntry ["vscode" "settings.json"];
          extensions = mkEntry ["vscode" "extensions.json"];
          tasks = mkEntry ["vscode" "tasks.json"];
          launch = mkEntry ["vscode" "launch.json"];
        };

        helix = {
          config = mkEntry ["helix" "config.toml"];
          languages = mkEntry ["helix" "languages.toml"];
        };

        zed = {
          settings = mkEntry ["zed" "settings.json"];
          tasks = mkEntry ["zed" "tasks.json"];
        };

        rustrover = {
          scopes = mkEntry ["idea" "scopes" "Project_Default.xml"];
          rust = mkEntry ["idea" "rust.xml"];
          misc = mkEntry ["idea" "misc.xml"];
          modules = mkEntry ["idea" "modules.xml"];
          cargo-run = mkEntry ["idea" "runConfigurations" "cargo.xml"];
          cargo-test = mkEntry ["idea" "runConfigurations" "tests.xml"];
          file-templates = mkEntry [
            "idea"
            "fileTemplates"
            "internal"
            "Rust_File.rs.ft"
          ];
        };

        neovim = {
          neoconf = {
            source =mkSource ["neovim" "neoconf.json"];
            target = ".neoconf.json";
          };
          config = {
            source = mkSource ["neovim" "nvim.lua"];
            target = ".nvim.lua";
          };
        };
      };
    };
    selected = with all;
      optionalAttrs includeBase base
      // optionalAttrs includeAI ai
      // optionalAttrs includeFormat format
      // optionalAttrs includeRust rust
      // optionalAttrs includeWeb web
      // (
        optionalAttrs
        (withEditor != "none")
        (editor.common // editor."${withEditor}")
      );
  in {inherit all selected;};

  deployConfig = {
    title ? "Configuration Deployment",
    description ? "Syncing project configuration files into your workspace",
    projectName ? project,
    includeAI ? true,
    includeFormat ? true,
    includeRust ? true,
    includeWeb ? false,
    pkgs ? mkPkgs {},
    style ? mkStyledOutput {inherit pkgs;},
    withEditor ? null,
  }: let
    templates = getTemplates {
      inherit
        includeAI
        includeFormat
        includeRust
        includeWeb
        pkgs
        projectName
        withEditor
        ;
    };
  in
    mkDeployConfig {inherit pkgs style templates title description;};
in {inherit anchor mkDeployConfig deployConfig;}
