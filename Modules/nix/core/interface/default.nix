{
  # config,
  host,
  lix,
  top,
  ...
}: let
  dom = "interface";
  # cfg = config.${top}.${dom};

  inherit (lix.schema.ui) mkOptions;
  # ui = mkUI {inherit host;};
in {
  # imports = lix.filesystem.importers.importAllPaths ./.;
  options.${top}.${dom} = mkOptions {inherit host;};
}
