{
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    "flake.lock"
    "*.age"
    "secrets/*.yaml"
  ];

  programs = {
    nixfmt = {
      enable = true;
    };

    deadnix = {
      enable = true;
      no-lambda-pattern-names = false;
    };

    statix.enable = true;

    prettier = {
      enable = true;
      includes = [
        "*.md"
        "*.json"
        "*.yaml"
        "*.yml"
      ];
    };

    shellcheck.enable = true;

    shfmt = {
      enable = true;
      indent_size = 2;
      simplify = true;
    };

    taplo.enable = true;
  };
}
