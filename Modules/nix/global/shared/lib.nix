args: let
  inherit (args) inputs lix pkgs;
  inherit (lix.sources.packages) pkgOf pkgsFrom;

  pkgsFor = {
    sources,
    required ? true,
  }:
    pkgsFrom {inherit inputs pkgs required sources;};

  pkgFor = {
    input,
    target ? null,
    required ? true,
  }:
    pkgOf {inherit input inputs pkgs required target;};
in {
  inherit pkgFor pkgsFor;
}
