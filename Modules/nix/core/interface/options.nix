# {
#   host,
#   lix,
#   top,
#   ...
# }: let
#   dom = "interface";
#   inherit (lix.schema.ui) mkOptions;
# in {
#   options.${top}.resolved.${dom} = mkOptions {inherit host;};
# }
{}
