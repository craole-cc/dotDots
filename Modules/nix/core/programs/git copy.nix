# {
#   config,
#   host,
#   lib,
#   lix,
#   top,
#   ...
# }: let
#   dom = "programs";
#   mod = "git";
#   cfg = config.${top}.${dom}.${mod};
#   user = host.users.data.primary or {};
#   hw = host.hardware;
#   inherit (config.${top}.interface) shellPrompt shell;
#   inherit (lix.lists.predicates) isIn;
#   inherit (lix.options) mkEnable mkTrue;
#   inherit (lib.modules) mkIf;
#   inherit (lib.options) mkEnableOption mkOption;
#   inherit (lib.types) bool;
# in {
#   options.${top}.${dom}.${mod} = {
#     enable = mkEnableOption mod // {default = true;};
#     bash = mkEnable "Bourne Again Shell" (isIn "bash" ([shell] ++ (user.shells or [])));
#     direnv = mkTrue "direnv";
#     git = mkTrue "git";
#     vimKeybinds = mkOption {
#       description = "Enable vim keybindings in shell";
#       default = user.interface.keyboard.vimKeybinds or false;
#       type = bool;
#     };
#     obs = mkEnable "OBS" hw.hasVideoCam;
#     starship = mkEnable "Starship Prompt" (shellPrompt == "starship");
#   };
#   config = mkIf cfg.enable {
#     programs = {
#       bash = mkIf cfg.bash.enable {
#         enable = true;
#         blesh.enable = true;
#         undistractMe.enable = true;
#       };
#       direnv = mkIf cfg.direnv.enable {
#         enable = true;
#         silent = true;
#         settings.global = {
#           log_format = "-";
#           log_filter = "^$";
#           load_dotenv = true;
#         };
#       };
#       starship = mkIf cfg.starship.enable {
#         enable = true;
#       };
#       git = mkIf cfg.git.enable {
#         enable = true;
#         lfs.enable = true;
#         prompt.enable = true;
#       };
#       obs-studio = mkIf (hw.hasVideoCam && cfg.obs.enable) {
#         enable = true;
#         enableVirtualCamera = true;
#       };
#       xwayland.enable = true;
#     };
#   };
# }
{}
