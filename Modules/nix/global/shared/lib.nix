{
  inputs,
  lix,
  pkgs,
  src,
  ...
}: let
  inherit (lix.sources.packages) pkgOf pkgsFrom;

  mkName = name: "${src.name}-${name}";

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
in {inherit mkName pkgFor pkgsFor;}
