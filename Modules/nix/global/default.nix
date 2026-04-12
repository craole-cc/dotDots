{
  inputs,
  lib,
  lix,
  path,
  pkgs,
  system,
  ...
}: let
  _ = {
    inherit inputs lib lix path pkgs system;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (pkgs) mkShell;
    inputPkgs = input:
      lix.sources.packages.fromInputs {
        inherit input inputs system;
      };

    #~@ Metadata
    name = "dots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";

    #~@ Options
    allowAI = true;

    #~@ Packages
    packages =
      []
      ++ minimal.packages
      ++ formatters
      ++ media.packages;
  };

  inherit
    (import ./fmt.nix {inherit pkgs path;})
    formatters
    formatter
    checks
    ;
  media = import ./media.nix {inherit pkgs;};
  dots = import ./dots.nix {inherit _;};
  minimal = import ./minimal.nix {inherit _;};
in {
  devShells = {
    default = minimal;
    media = media.shell;
    inherit dots minimal;
  };
  inherit formatter checks;
}
