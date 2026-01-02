# {
#   pkgs,
#   lib,
#   user,
#   lix,
#   inputs,
#   ...
# }: let
#   app = "vscode";
#   inherit (lib.lists) optionals;
#   inherit (lib.modules) mkIf;
#   inherit (lix.lists.predicates) isIn;
#   system = pkgs.stdenv.hostPlatform.system;
#   isAllowed = isIn app (
#     (user.applications.allowed or [])
#     ++ [(user.applications.editor.gui.primary or null)]
#     ++ [(user.applications.editor.gui.secondary or null)]
#   );
#   #> Use VSCode Insiders from inputs if available
#   vscodePackage = inputs.packages.vscode-insiders.${system}.default or pkgs.vscode;
# in {
#   config = mkIf isAllowed {
#     programs.${app} = {
#       enable = true;
#       package = vscodePackage;
#       profiles.default =
#         {
#           enableUpdateCheck = false;
#           enableExtensionUpdateCheck = false;
#         }
#         // import ./bindings.nix
#         // import ./editor.nix {inherit lib;}
#         // import ./extensions.nix {inherit pkgs;}
#         // import ./files.nix
#         // import ./git.nix
#         // import ./languages.nix
#         // import ./terminal.nix
#         // import ./theme.nix;
#     };
#     home.packages = [pkgs.vscode-fhs]; #? FHS wrapper for extension compatibility
#   };
# }
{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "vscode";
    kind = "editor";
    category = "gui";
    resolutionHints = ["vscode-insiders" "code" "code-insiders"];
    requiresWayland = true;
    extraPackages = [pkgs.vscode-fhs];
    extraProgramConfig = {
      profiles.default = mkMerge [
        {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
        }
        (import ./bindings.nix)
        (import ./editor.nix {inherit lib;})
        (import ./extensions.nix {inherit pkgs;})
        (import ./files.nix)
        (import ./git.nix)
        (import ./languages.nix)
        (import ./terminal.nix)
        (import ./theme.nix)
      ];
    };
    debug = true;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) home programs;
  };
}
