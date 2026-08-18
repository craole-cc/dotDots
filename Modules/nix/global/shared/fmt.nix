{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) path inputs;
  inherit (lix.sources.packages) pkgsFrom;

  sources = {
    actionlint = null;
    alejandra = null;
    dprint = null;
    harper = null;
    leptosfmt = null;
    rustfmt = null;
    shellcheck = null;
    shfmt = null;
    statix = null;
    stylua = null;
    tombi = null;
    treefmt = "treefmt";
    typos = null;
    typstyle = null;
  };

  resolved = pkgsFrom {
    inherit inputs pkgs sources;
    required = true;
  };

  #~@ Single source of truth: repo-root dprint.json, consumed by the CLI directly
  #~@ and derived here for the sandboxed/Nix-driven run.
  dprintConfig = builtins.fromJSON (builtins.readFile "${path}/dprint.json");

  #~@ Keys that route dprint's own file discovery — not formatting rules —
  #~@ and are superseded by treefmt's own includes/excludes/plugins below.
  dprintSettings =
    (builtins.removeAttrs dprintConfig ["$schema" "includes" "excludes" "plugins"])
    // {
      #~@ headingKind / listIndentKind removed: unsupported by dprint-plugin-markdown
      #~@ 0.20.0, the version currently packaged in nixpkgs. dprint.json (the CLI
      #~@ source of truth) keeps them for the newer plugin used outside the sandbox.
      markdown = builtins.removeAttrs dprintConfig.markdown ["headingKind" "listIndentKind"];
    };

  eval = inputs.treefmt.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      #~@ Nix
      alejandra.enable = true;
      statix.enable = true;

      #~@ Rust
      rustfmt.enable = true;
      leptosfmt.enable = true;

      #~@ Shellscript
      shellcheck.enable = true;
      shfmt = {
        enable = true;
        indent_size = 2;
        simplify = true;
      };

      #~@ Markup / config / data
      actionlint.enable = true;
      stylua.enable = true;
      typos.enable = true;
      typstyle.enable = true;

      dprint = {
        enable = true;
        includes = [
          "*.json"
          "*.jsonc"
          "*.md"
          "*.yaml"
          "*.yml"
          "*.css"
          "*.scss"
          "*.sass"
          "*.less"
        ];
        settings =
          dprintSettings
          // {
            plugins = pkgs.dprint-plugins.getPluginList (plugins:
              with plugins; [
                dprint-plugin-json
                dprint-plugin-markdown
                g-plane-pretty_yaml
                g-plane-malva
              ]);
          };
      };
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
        #~@ Nix
        alejandra.priority = 1;
        statix.priority = 2;

        #~@ Rust
        rustfmt.priority = 1;
        leptosfmt.priority = 2;

        #~@ Shellscript
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

        dprint = {
          priority = 1;
          options = ["--allow-no-files"];
        };
      };
    };
  };

  inherit (eval.config.build) wrapper check;
in {
  formatters = resolved.packages ++ [wrapper];
  formatter = wrapper;
  checks.formatting = check path;
}
