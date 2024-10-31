{
  pre-commit = {
    settings = {
      excludes = [
        "flake.lock"
        "r'.+.age$'"
        "r'.+.sh$'"
      ];
      hooks.treefmt.enable = true;
    };
    # devShell.shellHook = ''
    #   ${config.pre-commit.installationScript}
    # '';
  };
}
