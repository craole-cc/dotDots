{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) path inputs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.sources.packages) pkgsFrom;

  sources = {
    actionlint = null;
    alejandra = null;
    deno = null;
    leptosfmt = null;
    markdownlint-cli2 = null;
    rustfmt = null;
    shellcheck = null;
    shfmt = null;
    statix = null;
    stylua = null;
    tombi = null;
    treefmt = "treefmt-nix";
    typstyle = null;
    yamlfmt = null;
  };

  resolved = pkgsFrom {
    inherit inputs pkgs;
    inherit sources;
    required = true;
  };
  bins = mapAttrs (_: pkg: pkg.paths.exe) resolved;

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

      #~@ Mark[down/up]
      deno.enable = true;
      typstyle.enable = true;
      typos.enable = true;

      #~@ Config
      actionlint.enable = true;
      yamlfmt.enable = true;
      stylua.enable = true;
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

        #~@ Mark[down/up]
        deno.priority = 1;
        markdown = {
          command = bins.markdownlint-cli2;
          includes = ["*.md" "README"];
          options = [
            "--fix"
            "--config"
            ".markdownlint.yaml"
          ];
          priority = 2;
        };

        #~@ Config
        yamlfmt.priority = 1;
        actionlint.priority = 2;

        toml = {
          command = bins.tombi;
          includes = ["*.toml"];
          options = ["format" "--offline"];
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
