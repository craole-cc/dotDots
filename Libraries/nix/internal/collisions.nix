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
  {
    base ? lib,
    msg ? "Collisions encountered",
    overrides,
  }: let
    collisions = filter (n: elem n (attrNames base)) (attrNames overrides);
    hasCollisions = collisions != [];
    fullMsg = "${msg}: ${toString collisions}";
  in
    if !hasCollisions
    then base // overrides
    else if validated == "error"
    then throw fullMsg
    else if validated == "warn"
    then trace "WARNING: ${fullMsg}" (base // overrides)
    else if validated == "prefer-custom"
    then base // overrides
    else overrides // base
