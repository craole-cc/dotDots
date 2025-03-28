{
  perSystem =
    let

      includes = [
        "**/sh/**"
        "**/shellscript/**"
        "Modules/global/**"
        "Modules/nixos/configurations/hosts/QBX/bin/**"
        "**/bash/**"
        ".dotsrc"
        "*.shellcheckrc"
        "*.gitignore"
        "*.sh.*"
      ];
      excludes = [
        "*.nix"
        "*.md"
        "*.json"
        "*.yml"
        "*.yaml"
        "*.toml"
        "*.py"
        "*.rs"
      ];
    in
    {
      treefmt = {
        programs = {
          shellcheck = {
            # enable = true;
            priority = 1;
          };
          shfmt = {
            enable = true;
            priority = 2;
          };
        };
        settings.formatter = {
          # shellcheck = { inherit includes excludes; };
          shfmt = { inherit includes excludes; };
        };
      };
    };
}
