{
  lib,
  collisionStrategy,
}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) elem filter;
  inherit (lib.debug) trace;

  allowed = [
    "error"
    "warn"
    "prefer-custom"
    "prefer-nixpkgs"
  ];

  validated =
    if elem collisionStrategy allowed
    then collisionStrategy
    else
      throw ''
        Invalid collisionStrategy: ${toString collisionStrategy}
        Expected one of: ${toString allowed}
      '';
in
  customAttrs: let
    collisions = filter (
      n: elem n (attrNames lib)
    ) (attrNames customAttrs);
    hasCollisions = collisions != [];
    msg = "Custom library has collisions with nixpkgs lib: ${
      toString collisions
    }";
  in
    if !hasCollisions
    then lib // customAttrs
    else if validated == "error"
    then throw msg
    else if validated == "warn"
    then trace "WARNING: ${msg}" (lib // customAttrs)
    else if validated == "prefer-custom"
    then lib // customAttrs
    else customAttrs // lib
