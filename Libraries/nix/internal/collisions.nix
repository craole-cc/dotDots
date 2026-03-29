{
  lib',
  collisionStrategy,
}: let
  inherit (lib'.attrsets) attrNames;
  inherit (lib'.lists) elem filter;
  inherit (lib'.debug) trace;
in
  customAttrs: let
    collisions = filter (n: elem n (attrNames lib')) (attrNames customAttrs);
    hasCollisions = collisions != [];
    msg = "Custom library has collisions with nixpkgs lib: ${toString collisions}";
  in
    if !hasCollisions
    then lib' // customAttrs
    else if collisionStrategy == "error"
    then throw msg
    else if collisionStrategy == "warn"
    then trace "WARNING: ${msg}" (lib' // customAttrs)
    else if collisionStrategy == "prefer-custom"
    then lib' // customAttrs
    else if collisionStrategy == "prefer-nixpkgs"
    then customAttrs // lib'
    else lib' // customAttrs
