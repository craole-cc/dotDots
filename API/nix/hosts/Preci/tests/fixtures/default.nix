# {lix, ...}: let
#   inherit (lix.attrsets) filterAttrs mapAttrs;
#   inherit (lix.filesystem) readDir;
# in {
#   importAll = dir: let
#     files = readDir dir;
#     filteredFiles = filterAttrs (name: _: name != "default.nix") files;
#   in
#     mapAttrs (name: file: import "${dir}/${file}") filteredFiles;
# }
import ./cpus.nix
