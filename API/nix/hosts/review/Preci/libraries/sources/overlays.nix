{
  lix,
  inputs,
  overlays,
  ...
}: let
  inherit (lix.attrsets) listToAttrs;
in
  listToAttrs (
    map (name: {
      inherit name;
      value = import inputs.${name}.path;
    })
    overlays
  )
