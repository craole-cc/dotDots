{
  host,
  lix,
  top,
  ...
}: let
  dom = "interface";
  inherit (lix.schema.ui) mkOptions;
in {
  options.${top}.inputs.${dom} = mkOptions {inherit host;};
}
