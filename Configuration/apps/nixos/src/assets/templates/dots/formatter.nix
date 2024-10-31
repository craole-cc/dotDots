{ config, ... }:
{
  config.treefmt = {
    # inherit (config.flake-root) projectRootFile;
    projectRootFile = "flake.nix";

    programs = {
      # | Nix
      nixfmt-rfc-style.enable = true;
      deadnix.enable = true;
      statix = {
        enable = true;
        # disabled-lints = ["repeated_keys"];
      };

      # | Shellscript
      shellcheck.enable = true;
      shfmt = {
        enable = true;
        indent_size = 0; # Default 2, Use 0 for tabs
      };
      # TODO: How to lint based on shebang or a specific folder as type?

      # | General
      # biome = {
      #   enable = true;
      #   settings.formatter.enabled = true;
      # };
      # deno.enable = true;
      prettier.enable = true; # Multi-language
      stylua.enable = true;
      yamlfmt.enable = true; # LANG YAML
      taplo.enable = true; # LANG TOML
      ruff.enable = true; # LANG Python
      rufo.enable = true; # LANG Ruby
      rustfmt.enable = true; # LANG Rust
      # TODO: How to lint markdown?
    };

    settings.formatter = {
      # alejandra.excludes = ["generated.nix"];
      deadnix.excludes = [ "generated.nix" ];
      statix.excludes = [ "generated.nix" ];
      stylua.options = [
        "--indent-type"
        "Spaces"
        "--indent-width"
        "2"
        "--quote-style"
        "ForceDouble"
      ];
    };
  };
}
