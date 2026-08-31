{lix, ...}: {imports = (lix.filesystem.traversal ./.).value;}
# {
#   lib,
#   lix,
#   inputs ? {},
#   ...
# }: let
#   inherit (builtins) filter;
#   imports = lix.filesystem.traversal.importAllPaths ./.;
#   hasCaelestia = inputs.caelestia ? homeManagerModules;
#   hasNoctalia = inputs.noctalia-shell ? homeModules;
#   hasQuickshell = inputs.quickshell ? packages;
# in {
#   imports =
#     filter (
#       path:
#         (hasCaelestia || path != ./components/caelestia)
#         && (hasNoctalia || path != ./components/noctalia)
#         && (hasQuickshell || path != ./components/quickshell)
#     )
#     imports;
# }
