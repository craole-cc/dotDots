{ pkgs }:

let
  # Collect all formatting-related packages
  formatterPackages = with pkgs; [
    treefmt2
    nixfmt-rfc-style
    biome
    ruff
    shellcheck
    shfmt
    yamlfmt
  ];

  # Additional development tools
  devTools = with pkgs; [
    git
    nix
    curl
  ];
in
{
  # Create treefmt configuration with the specified formatters
  programs = {
    # Nix formatting using nixfmt-rfc-style
    nixfmt-rfc-style.enable = true;

    # JavaScript/TypeScript formatting with Biome
    biome = {
      enable = true;
      settings = { };
    };

    # Python formatting with Ruff
    ruff = {
      enable = true;
      settings = {
        line-length = 88;
        target-version = "py310";
      };
    };

    # Shell script formatting with shfmt
    shfmt = {
      enable = true;
      options = [
        "-i"
        "2" # Indent with 2 spaces
        "-bn" # Place function braces on the same line
        "-ci" # Switch case indent
        "-sr" # Redirect to same line
      ];
    };

    # Shellcheck with all checks enabled (strict mode)
    shellcheck = {
      enable = true;
      settings = {
        severity = "error";
      };
    };
  };

  # Global settings for treefmt
  global = {
    excludes = [
      ".git"
      "node_modules"
      "target"
    ];
  };

  # Expose packages for use in the dev shell
  devInputs = formatterPackages ++ devTools;
}
