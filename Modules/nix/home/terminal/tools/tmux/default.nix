# #TODO: The modules need to be options, not hardcoded
# {
#   config,
#   lix,
#   user,
#   pkgs,
#   ...
# }: let
#   dom = "terminal";
#   mod = "tmux";
#   inherit (lix.modules.construction) mkConfig mkMerge;
#   inherit (lix.options.construction) mkEnableOption;
#   inherit (lix.applications.generators) userApplicationConfig;
#   resolved = userApplicationConfig {
#     inherit user pkgs config dom mod;
#     extraProgramConfig = mkMerge [
#       (import ./plugins.nix)
#     ];
#     debug = false;
#   };
# in
#   mkConfig {
#     inherit config dom mod;
#     options = {
#       enable = mkEnableOption mod // {default = resolved.enable;};
#     };
#     outputs = {inherit (resolved) programs home;};
#   }
#TODO: The modules need to be options, not hardcoded
{
  config,
  lix,
  user,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "tools";
    mod = "tmux";
  };

  inherit (lix.modules.construction) mkConfig mkContext mkMerge;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.applications.generators) userApplicationConfig;

  resolved = userApplicationConfig {
    inherit context pkgs user;
    extraProgramConfig = mkMerge [
      (import ./plugins.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = resolved.enable;
      };
    };
    outputs = {inherit (resolved) programs home;};
  }
