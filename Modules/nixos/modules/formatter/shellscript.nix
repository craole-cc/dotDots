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
      formatter = fmt.wrapper;
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
        settingsformatter = {
          # shellcheck = { inherit (sh) includes excludes; };
          shfmt = { inherit (sh) includes excludes; };
        };
      };
    };
}
