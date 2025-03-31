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
            excludes = includes;
            # inherit includes;
            # excludes = excludes ++ [ "**/QBX/bin/**" ];
            options = [
              # "--enable=all"

              #> Disable Warnings
              # "disable=SC2154" # ? Variable is referenced but not assigned
              # "disable=SC1090-SC1091" # ? Can't follow non-constant source. Use a directive to specify location.
              # "disable=SC2034" # ? Unused variables.
              # "disable=SC2317" # ? Command appears to be unreachable. Check usage (or ignore if invoked indirectly).
            ];
          };
          shfmt = {
            inherit includes excludes;
            # indent_size = 4; #TODO: this doesn't seem to work
            options = [
              "--apply-ignore" # TODO: this doesn't seem to work
              "--binary-next-line"
              "--space-redirects"
              "--case-indent"
            ];
          };
        };
      };
    };
}
