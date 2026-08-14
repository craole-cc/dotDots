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
    name ? "default",
    required ? true,
  }:
    pkgOf {inherit input inputs name pkgs required;};
in {
  inherit pkgFor pkgsFor;
}
