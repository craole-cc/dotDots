{
  deploy-rs,
  nixpkgs,
  ragenix,
  ...
}:
let
  inherit (nixpkgs) lib;
  localOverlays = lib.mapAttrs' (
    f: _: lib.nameValuePair (lib.removeSuffix ".nix" f) (import (../middleware + "/${f}"))
  ) (builtins.readDir ../middleware);
in
localOverlays
// {
  default = lib.composeManyExtensions (
    (lib.attrValues localOverlays)
    ++ [
      deploy-rs.overlay
      ragenix.overlays.default
    ]
  );
}
