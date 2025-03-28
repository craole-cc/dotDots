{
  perSystem =
    { pkgs, ... }:
    let
      fmt = {
        packages = with pkgs; [
          shellcheck
          shfmt
        ];
      };
      sh = {
        includes = [
          "**/sh/**"
          # "**/shellscript/**"
          "**/bash/**"
        ];
        excludes = [
          "*.nix"
        ];
      };
    in
    {
      _module.args = { inherit fmt; };
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
          # shellcheck = { inherit (sh) includes excludes; };
          shfmt = { inherit (sh) includes excludes; };
        };
      };
    };
}
