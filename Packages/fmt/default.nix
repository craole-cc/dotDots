{
  evalModule,
  pkgs,
  flake,
}: let
  eval = evalModule pkgs {
    projectRootFile = "flake.nix";

    programs = {
      # Nix formatters
      alejandra.enable = true;
      deadnix.enable = true;

      # Shell scripts
      shellcheck.enable = true;
      shfmt.enable = true;

      # Markdown
      mdformat.enable = true;

      # YAML/TOML
      yamlfmt.enable = true;
      taplo.enable = true;

      # JSON
      prettier = {
        enable = true;
        includes = ["*.json" "*.jsonc"];
      };
    };
  };
in
  with eval.config.build; {
    formatter = wrapper;
    formatting = check flake;
  }
