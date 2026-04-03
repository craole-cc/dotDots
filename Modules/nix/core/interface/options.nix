{
  host,
  lix,
  top,
  ...
}: let
  dom = "interface";
  inherit (lix.schema.ui) mkUI mkUIOptions;
  ui = mkUI {inherit host;};
in {
  _module.args.${dom} = {inherit ui;};
  options.${top}.${dom} = mkUIOptions {inherit ui;};
}
