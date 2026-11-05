{
  host,
  lix,
  top,
  ...
}: let
  inherit (lix.schema.ui) mkOptions;
in {
  options.${top}.resolved.interface = mkOptions {
    ui = host.interface;
  };
}
