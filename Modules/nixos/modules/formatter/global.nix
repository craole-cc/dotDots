{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      fmt = {
        config = config.treefmt.build.configFile;
        packages = with pkgs; [
          #TODO: These should not be necessary since the wrapper is actuall a package of the entire treefmt config.
          treefmt
          biome
          alejandra
          deadnix
          shellcheck
          shfmt
          mdsh
          taplo
          yamlfmt
          nodePackages.prettier
        ];
        wrapper = config.treefmt.build.wrapper;
      };
    in
    {
      _module.args = { inherit fmt; };
      formatter = fmt.wrapper;
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
