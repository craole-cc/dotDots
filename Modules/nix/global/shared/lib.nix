args: let
  inherit (args) inputs lix pkgs;
  inherit (lix.sources.packages) pkgOf pkgsFrom;

  pkgFor = {
    input,
    target ? null,
    required ? true,
  }:
    pkgOf {inherit input inputs pkgs required target;};

  pkgsFor = {
    sources,
    required ? true,
    exclude ? [],
  }:
    pkgsFrom {inherit inputs pkgs required sources exclude;};
in {inherit pkgFor pkgsFor;}
