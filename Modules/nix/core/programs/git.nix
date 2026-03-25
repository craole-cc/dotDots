{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "git";
  cfg = config.${top}.${dom}.${mod};
  inherit (lix.types.options) mkTrue mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue "Git distributed version control software system";
    enableLFS = mkTrue "Large File Storage for Git";
    enablePrompt = mkTrue "Utility functions via `git-prompt.sh`";
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable;
      lfs.enable = cfg.enableLFS;
      prompt.enable = cfg.enablePrompt;
    };
  };
}
