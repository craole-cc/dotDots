{
  pkgs,
  lib,
  path,
  lix,
  system,
  ...
}: let
  configuration = {
    name = "dots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
  };

  inherit
    (import ./fmt.nix {inherit pkgs path;})
    formatters
    formatter
    checks
    ;
  media = import ./media.nix {
    inherit pkgs;
  };
  dots = import ./dots.nix {
    inherit pkgs lix lib system;
    mediaPackages = media.packages;
    fmtPackages = formatters;
  };
  minimal = import ./minimal.nix {
    inherit lib pkgs system configuration;
  };
in {
  devShells = {
    default = minimal;
    media = media.shell;
    inherit dots minimal;
  };
  inherit formatter checks;
}
