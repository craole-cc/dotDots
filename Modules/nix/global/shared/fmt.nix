{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) path inputs;
  inherit (inputs.treefmt.lib) evalModule;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.modules.construction) mkForce;
  inherit (lix.sources.packages) pkgsFrom;
  inherit (lix.strings.construction) fromJSON;
  inherit (pkgs) writeShellScriptBin;

  resolved = let
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
  in
    pkgsFrom {
      inherit inputs pkgs sources;
      required = true;
    };
  inherit (resolved) packages;
  binaries = mapAttrs (_: pkg: pkg.paths.exe) resolved;

  dprint = let
    config = fromJSON (readFile "${path}/dprint.json");
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
        plugins = pkgs.dprint-plugins.getPluginList (plugins:
          with plugins; [
            dprint-plugin-json
            dprint-plugin-markdown
            g-plane-pretty_yaml
            g-plane-malva
          ]);
      };
  };

  treefmt = let
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
          typos.includes = ["Configuration/rofi/launcher/type-1"];
        };
      };
    };

    #~@ Nix-side eval: store-path commands, used by `nix fmt`.
    imported = {
      inherit module;
      eval = evalModule pkgs module;
    };

    #~@ Portable eval: same module, bare commands resolved via PATH,
    #~@ exported to .treefmt.toml for use outside Nix (e.g. Windows).
    exported = let
      names = [
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

      module' =
        module
        // {
          settings =
            module.settings
            // {
              formatter =
                recursiveUpdate
                module.settings.formatter
                (
                  (mapAttrs (_: name: {command = mkForce name;}))
                  (genAttrs names (name: name))
                  // {
                    dprint.options = mkForce [
                      "fmt"
                      "--allow-no-files"
                      "--config"
                      "dprint.json"
                    ];
                  }
                );
            };
        };
    in {
      inherit names;
      module = module';
      eval = evalModule pkgs module';
    };

    inherit (imported.eval.config.build) wrapper check;
    inherit (exported.eval.config.build) configFile;

    sync = let
      name = "sync-treefmt-toml";
      script = writeShellScriptBin name ''
        set -euo pipefail
        root="$(${binaries.git} rev-parse --show-toplevel)"
        cp --force ${configFile} "$root/.treefmt.toml"
        chmod u+w "$root/.treefmt.toml"
        printf "Synced .treefmt.toml (portable) from fmt.nix\n"
      '';
      value = {
        type = "app";
        program = "${script}/bin/${name}";
      };
    in {inherit name value;};
  in {
    apps = {${sync.name} = sync.value;};
    formatter = wrapper;
    checks.formatting = check path;
  };
in {
  inherit (treefmt) apps checks formatter;
  formatters = packages ++ [treefmt.formatter];
}
