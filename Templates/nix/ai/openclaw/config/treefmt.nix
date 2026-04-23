_: {
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    "flake.lock"
    "*.age"
    "secrets/*.yaml"
  ];

  programs = {
    #~@ Nix
    # alejandra.enable = true;
    nixfmt.enable = true;
    # deadnix = {
    #   enable = true;
    #   no-lambda-pattern-names = false;
    # };
    statix.enable = true;

    #~@ Markup
    prettier = {
      enable = true;
      includes = [
        "*.md"
        "*.json"
        "*.yaml"
        "*.yml"
      ];
    };
    taplo.enable = true;

    #~@ Shellscript
    shellcheck.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
      simplify = true;
    };
  };
}
