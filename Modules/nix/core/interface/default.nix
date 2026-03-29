{
  config,
  lix,
  top,
  host,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.${dom};

  inherit (lix.schema.ui) mkUI;
  ui = mkUI {inherit host;};
in {
  imports = lix.filesystem.importers.importAllPaths ./.;
  _module.args.${dom} = ui // {inherit cfg;};
}
