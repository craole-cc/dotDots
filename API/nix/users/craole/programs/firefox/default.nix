# {
#   config,
#   host,
#   icons,
#   inputs,
#   lib,
#   lix,
#   pkgs,
#   policies,
#   user,
#   ...
# }: let
#   inherit (lix.trivial) isNotEmpty;
#   inherit (lix.generators.firefox) mkModule;
#   variant = user.applications.browser.firefox or null;
#   firefox = mkModule {inherit inputs pkgs policies variant;};
# in {
#   # _module.args = {
#   #   browsers = {inherit firefox;};
#   # };
#   imports =
#     [
#       (import ./config.nix {
#         inherit
#           firefox
#           lib
#           lix
#           icons
#           host
#           user
#           config
#           ;
#       })
#     ]
#     ++ (
#       with firefox.zen;
#         if isNotEmpty module
#         then [module]
#         else []
#     )
#     ++ [];
# }
{imports = [./zen.nix];}
