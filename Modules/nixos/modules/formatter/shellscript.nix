{
  perSystem =
    let
      global = {
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
      };
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
            includes = [
              "Bin/shellscript/environment/enviro"
            ];
            excludes = [
              "**/QBX/bin/**"
            ] ++ global.excludes;
            #   ++ global.includes;
            options = [
              "--extended-analysis=false"
              "--wiki-link-count=0"

              # "--enable=all"
              "--exclude=1090"
              "--exclude=1091"
              "--exclude=2003"
              "--exclude=2031"
              "--exclude=2034"
              "--exclude=2317"
            ];
          };
          shfmt = {
            includes = global.includes ++ [ ];
            excludes = global.excludes ++ [ ];
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
