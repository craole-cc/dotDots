{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {...}: {
    treefmt = {
      settings.global.excludes = [
        "flake.lock"
        "*.age"
        "secrets/*.yaml"
      ];

      programs = {
        #~@ Nix
        nixfmt = {
          enable = true;
          package = null;
        };
        deadnix = {
          enable = true;
          no-lambda-pattern-names = false;
        };
        statix.enable = true;

        #~@ Markdown, JSON, YAML, TOML front-matter
        prettier = {
          enable = true;
          includes = [
            "*.md"
            "*.json"
            "*.yaml"
            "*.yml"
          ];
        };

        #~@ Shell scripts
        shellcheck.enable = true;
        shfmt = {
          enable = true;
          indent_size = 2;
          simplify = true;
        };

        #~@ TOML
        taplo.enable = true;
      };
    };
  };
}
