{ lib }:
lib.assembly.importAttrs {
  inherit lib;
  path = ./.;
  ignore = ["meta.nix" ];
}
