# { lib, ... }:
# let
#   # dib = {
#   lists = import ./lists.nix { inherit lib; };
#   filesystem = import ./filesystem.nix {
#     inherit lib;
#     dib = lists;
#   };
# in
# # };
# {
#   inherit lists filesystem;
# }
{imports=[./filesystem.nix];}
