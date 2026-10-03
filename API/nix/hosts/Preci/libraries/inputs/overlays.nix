{
  lix,
  sources,
  overlays,
  ...
}: let
  inherit (lix.attrsets) listToAttrs;
in
  listToAttrs (
    map (name: {
      inherit name;
      value = import sources.${name}.path;
    })
    overlays
  )
