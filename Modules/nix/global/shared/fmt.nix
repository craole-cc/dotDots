{
  inputs,
  pkgFor,
  pkgs,
  paths,
  ...
}: let
  path = paths.src.store;
  treefmt = pkgFor {
    input = "treefmt-nix";
    target = "treefmt";
  };

  config = inputs.treefmt.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      alejandra.enable = true;
      statix.enable = true;
      rustfmt.enable = true;
      shellcheck.enable = true;
      shfmt = {
        enable = true;
        indent_size = 2;
        simplify = true;
      };
      stylua.enable = true;
      typstyle.enable = true;
      yamlfmt.enable = true;
    };

    settings = {
      global.excludes = [
        ".dotsrc"
        "LICENSE"
        "**/node_modules/**"
        "**/target/**"
        "**/.git/**"
        "**/dist/**"
        "**/build/**"
        "**/review/**"
        "**/archive/**"
        "*.lock"
        "Assets/**"
        "*.diff"
        "*.patch"
        "AGENTS.md"
        "**/dump.nix"
        "**/.bin/**"
        "**/.config/**"
        "**README.md"
        ".zed/**"
        "Configuration/**"
        "Documentation/**"
        "Environment/**"
        "Modules/global/**"
        "Modules/nixos/configurations/hosts/QBX/**"
        "Modules/nixos/scripts/**"
        "Review/**"
        "Scripts/**"
        "Tasks/**"
        "Templates/**"
      ];

      formatter = {
        alejandra.priority = 1;
        statix.priority = 2;

        rustfmt = {
          priority = 1;
          # options = ["--edition" "2024"];
        };

        shellcheck = {
          priority = 1;
          options = [
            "--rcfile"
            ".shellcheckrc"
          ];
        };

        shfmt = {
          priority = 2;
          options = [
            "--apply-ignore"
            "--binary-next-line"
            "--space-redirects"
            "--case-indent"
          ];
        };

        toml = {
          command = "${pkgs.tombi}/bin/tombi";
          includes = ["*.toml"];
          options = ["format" "--offline"];
        };

        markdown = {
          command = "${pkgs.markdownlint-cli2}/bin/markdownlint-cli2";
          includes = ["*.md" "README"];
          options = [
            "--fix"
            "--config"
            ".markdownlint.yaml"
          ];
          priority = 1;
        };

        deno = {
          command = "${pkgs.deno}/bin/deno";
          includes = [
            "*.css"
            "*.html"
            "*.js"
            "*.json"
            "*.jsonc"
            "*.jsx"
            "*.less"
            "*.markdown"
            "*.md"
            "*.sass"
            "*.scss"
            "*.ts"
            "*.tsx"
            "*.yaml"
            "*.yml"
          ];
          options = ["fmt"];
          priority = 2;
        };

        actionlint = {
          command = "${pkgs.actionlint}/bin/actionlint";
          includes = [
            ".github/workflows/*.yml"
            ".github/workflows/*.yaml"
          ];
          priority = 2;
        };
      };
    };
  };

  formatter = config.config.build.wrapper;

  formatters = with pkgs; [
    actionlint
    alejandra
    deno
    leptosfmt
    markdownlint-cli2
    nixfmt
    prettierd
    rustfmt
    shellcheck
    shfmt
    statix
    stylua
    tombi
    typstyle
    yamlfmt
    formatter
  ];
in {
  inherit formatter formatters;
  checks.formatting = config.config.build.check path;
}
