{
  lix,
  paths,
  ...
}: let
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) str;
in {
  folders = mapAttrs (name: default:
    mkOption {
      type = str;
      inherit default;
      description = "Directory for ${name} wallpapers.";
    }) {
    inherit (paths.variety.wallpapers) downloaded fetched;
    preferred = paths.wallpapers.preferred;
  };
}
