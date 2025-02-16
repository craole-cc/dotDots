{pkgs, ...}: let
  #@ Define the content of treefmt.toml
  treefmtConfig = ''
    [global]
    excludes = ["treefmt.toml", "generated.nix"]

    [formatter.nixfmt]
    command = "nixfmt"
    includes = ["*.nix"]
    priority = 1

    # [formatter.alejandra]
    # command = "alejandra"
    # includes = ["*.nix"]
    # priority = 1

    # [formatter.deadnix]
    # command = "deadnix"
    # options = ["-e"]
    # includes = ["*.nix"]
    # priority = 2

    # [formatter.statix]
    # command = "statix"
    # options = ["check"]
    # includes = ["*.nix"]
    # priority = 3

    [formatter.rust]
    command = "rustfmt"
    includes = ["*.rs"]

    [formatter.shellcheck]
    command = "shellcheck"
    includes = ["*.sh"]
    options = ["-i", "2", "-s"]
    priority = 2

    [formatter.shfmt]
    command = "shfmt"
    includes = ["*.sh"]
    options = ["-i", "2", "-s"]

    [formatter.python]
    command = "ruff"
    includes = ["*.py"]
    options = ["format", "--quiet"]

    [formatter.json]
    command = "jq"
    includes = ["*.json", "*.jsonc"]
    options = ["--indent", "2", "--sort-keys"]

    [formatter.toml]
    command = "taplo"
    includes = ["*.toml"]
    options = ["fmt"]

    [formatter.markdown]
    command = "markdownlint"
    includes = ["*.md"]
    options = ["--prose-wrap", "always", "--write"]
  '';

  #@ Write the treefmt.toml file to a temporary location
  treefmtConfigFile = pkgs.writeText "treefmt.toml" treefmtConfig;

  # #@ Create a script to deploy treefmt.toml and run treefmt
  # treefmtScript = pkgs.writeShellScriptBin "tfmt" ''
  #   rm -rf ./treefmt.toml
  #   cp ${treefmtConfigFile} ./treefmt.toml
  #   treefmt --config-file ./treefmt.toml "$@"
  # '';
  # Create a script to search for treefmt.toml and run treefmt
  treefmtScript = pkgs.writeShellScriptBin "tfmt" ''
    # Function to find the nearest treefmt.toml file
    find_treefmt_config() {
      local dir="$1"
      while [ "$dir" != "/" ]; do
        if [[ -f "$dir/treefmt.toml" ]]; then
          printf "%s" "$dir/treefmt.toml"
          return
        fi
        dir="$(dirname "$dir")"
      done

      # Check the home directory
      if [[ -f "$HOME/.config/treefmt/treefmt.toml" ]]; then
        printf "%s" "$HOME/.config/treefmt/treefmt.toml"
        return
      fi

      # Fall back to the default configuration
      printf "%s" "${treefmtConfigFile}"
    }

    # Find the treefmt.toml file
    CONFIG_FILE=$(find_treefmt_config "$(pwd)")

    # Run treefmt using the found or default treefmt.toml file
    treefmt --config-file "$CONFIG_FILE" "$@"
  '';
in {
  environment = {
    systemPackages = with pkgs; [
      curl
      fd
      sd
      git
      helix
      treefmt2
      nil
      nixd
      alejandra
      deadnix
      statix
      nixfmt-rfc-style
      rustfmt
      shfmt
      shellcheck
      ruff
      jq
      markdownlint-cli
      taplo
      treefmtScript
      imagemagick
      speedtest-go
    ];

    variables = {
      EDITOR = "hx";
      VISUAL = "code";
    };
  };
}
