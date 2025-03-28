{
  perSystem =
    let

      includes = [
        "**/sh/**"
        "**/shellscript/**"
        "**/Scripts/**"
        "Scripts/**"
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
        "LICENSE"
        ".editorconfig" # TODO: We should be able to format this with ini
      ];
    in
    {
      treefmt = {
        programs = {
          shellcheck = {
            enable = true;
            priority = 1;
          };
          shfmt = {
            enable = true;
            priority = 2;
          };
        };
        settings.formatter = {
          shellcheck = {
            inherit includes excludes;
            options = [
              "--enable=all"
            ];
          };
          shfmt = {
            inherit includes excludes;
            # indent_size = 4; #TODO: this doesn't seem to workFf
            options = [
              "--apply-ignore" # TODO: this doesn't seem to workFf
              "--binary-next-line"
              "--space-redirects"
              "--case-indent"
            ];
          };
        };
      };
    };
}
