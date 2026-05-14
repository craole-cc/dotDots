{
  host,
  lix,
  top,
  ...
}:
let
  dom = "interface";
  inherit (lix.schema.ui) mkOptions;
in
{
  options.${top}.${dom} = mkOptions { inherit host; };
}
