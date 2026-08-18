{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) path inputs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.sources.packages) pkgsFrom;
  inherit (lix.strings.construction) fromJSON;

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

  dprint = let
    config = fromJSON (readFile "${path}/dprint.json");
    settings =
      (removeAttrs config [
        "$schema"
        "includes"
        "excludes"
        "plugins"
      ])
      // {
        markdown = removeAttrs config.markdown [
          "headingKind"
          "listIndentKind"
        ];
      }
      // {
        plugins = pkgs.dprint-plugins.getPluginList (plugins:
          with plugins; [
            dprint-plugin-json
            dprint-plugin-markdown
            g-plane-pretty_yaml
            g-plane-malva
          ]);
      };
  in {
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
    inherit settings;
  };

  treefmt = inputs.treefmt.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      inherit dprint;

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

  inherit (treefmt.config.build) wrapper check configFile;

  syncTreefmtToml = pkgs.writeShellScriptBin "sync-treefmt-toml" ''
    set -euo pipefail
    cp --force ${configFile} "${path}/.treefmt.toml"
    chmod u+w "${path}/.treefmt.toml"
    echo "Synced .treefmt.toml from fmt.nix"
  '';
  apps = {
    sync-treefmt-toml = {
      type = "app";
      program = "${syncTreefmtToml}/bin/sync-treefmt-toml";
    };
  };
in {
  inherit apps;
  formatters = resolved.packages ++ [wrapper];
  formatter = wrapper;
  checks.formatting = check path;
}
