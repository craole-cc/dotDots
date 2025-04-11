{
  perSystem =
    {
      config,
      ...
    }:
    {
      formatter = config.treefmt.build.wrapper;
      treefmt = {
        projectRootFile = "flake.nix";
        settings = {
          global = {
            on-unmatched = "error";
            excludes = [
              "**/node_modules/**"
              "**/target/**"
              "**/review/**"
              "**/temp/**"
              "Review/**"
              "Configuration/**" # TODO: This is temporary
              "Environment/**" # TODO: This is temporary
              "Tasks/**" # TODO: This is temporary
              "Templates/**" # TODO: This is temporary
              "**/.config/**"
              "Assets/**"
              "*.bat"
              "*.cmd"
              "*.ps1" # TODO: Find a way to format these
              "*.editorconfig"
              "LICENSE"
              # "*.ascii"
              # "*.webp"
              # "*.png"
              # "*.jpg"
              # "*.jpeg"
              # "*.gif"
              # "*.svg"
              # "*.ico"
            ];
          };
        };
      };
    };
}
