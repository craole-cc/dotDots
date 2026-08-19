{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) path inputs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.sources.packages) pkgsFrom;
  inherit (lix.strings.construction) fromJSON;
  inherit (pkgs) writeShellScriptBin;

  sources = {
    git = null;
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
  bins = mapAttrs (_: pkg: pkg.paths.exe) resolved;

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

  #~@ Shared module body — evaluated twice below: once as-is for `nix fmt`
  #~@ (store-path commands), once with bare commands for the portable
  #~@ (non-Nix, e.g. Windows) .treefmt.toml export.
  module = {
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

  treefmt = inputs.treefmt.lib.evalModule pkgs module;

  #~@ Portable eval: same module body, formatter commands overridden to
  #~@ bare names (resolved via PATH on the target machine) and dprint's
  #~@ --config path made relative, so the generated .treefmt.toml works
  #~@ outside Nix (e.g. on Windows, where /nix/store paths don't exist).
  portableFormatterNames = [
    "actionlint"
    "alejandra"
    "dprint"
    "leptosfmt"
    "rustfmt"
    "shellcheck"
    "shfmt"
    "statix"
    "stylua"
    "typos"
    "typstyle"
  ];

  portableModuleBody =
    module
    // {
      settings =
        module.settings
        // {
          formatter =
            lix.attrsets.aggregation.recursiveUpdate
            module.settings.formatter
            (
              (mapAttrs (_: name: {command = name;}))
              (lix.attrsets.construction.genAttrs portableFormatterNames (n: n))
              // {
                dprint.options = ["fmt" "--allow-no-files" "--config" "dprint.json"];
              }
            );
        };
    };

  portableTreefmt = inputs.treefmt.lib.evalModule pkgs portableModuleBody;

  inherit (treefmt.config.build) wrapper check;
  inherit (portableTreefmt.config.build) configFile;

  apps = let
    sync = "sync-treefmt-toml";
  in {
    ${sync} = {
      type = "app";
      program = "${writeShellScriptBin sync ''
        set -euo pipefail
        repo_root="$(${bins.git} rev-parse --show-toplevel)"
        cp --force ${configFile} "$repo_root/.treefmt.toml"
        chmod u+w "$repo_root/.treefmt.toml"
        echo "Synced .treefmt.toml (portable) from fmt.nix"
      ''}/bin/${sync}";
    };
  };
in {
  inherit apps;
  formatters = resolved.packages ++ [wrapper];
  formatter = wrapper;
  checks.formatting = check path;
}
