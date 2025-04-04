{
  perSystem =
    { pkgsUnstable, ... }:
    let
      includes = [
        "**/nix/**"
        "*.nix.*"
      ];
      excludes = [
        "*.sh"
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
          nixfmt = {
            enable = true;
            package = pkgsUnstable.nixfmt-rfc-style;
            # priority = 2;
          };
          # deadnix = {
          #   enable = true;
          #   priority = 1;
          # };
        };
        settings.formatter = {
          nixfmt = {
            inherit includes excludes;
          };
        };
      };
    };
}
