{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "git";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.options.construction) mkTrue;
  inherit (lix.modules.construction) mkConfig;
in
  mkConfig {
    inherit config top dom mod;
    options = {
      enable = mkTrue "Git distributed version control software system";
      enableLFS = mkTrue "Large File Storage for Git";
      enablePrompt = mkTrue "Utility functions via `git-prompt.sh`";
    };
    outputs = {
      programs.${mod} = {
        inherit (cfg) enable;
        lfs.enable = cfg.enableLFS;
        prompt.enable = cfg.enablePrompt;
      };
    };
  }
