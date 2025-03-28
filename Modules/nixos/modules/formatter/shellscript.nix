{
  perSystem =
    let

      includes = [
        "**/sh/**"
        "**/shellscript/**"
        "**/Scripts/**"
        "**/scripts/**"
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
        "*.go"
        "*.c"
        "*.cpp"
        "*.bat"
        "*.ps1"
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
