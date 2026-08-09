{
  config,
  lix,
  lib,
  top,
  ...
}: let
  dom = "programs";
  mod = "git";
  cfg = config.${top}.inputs.${dom}.${mod};
  inherit (lix.options.construction) mkTrue;
  inherit (lix.modules.construction) mkIf;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkTrue "Git distributed version control software system";
    enableLFS = mkTrue "Large File Storage for Git";
    enablePrompt = mkTrue "Utility functions via `git-prompt.sh`";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable;
      lfs.enable = cfg.enableLFS;
      prompt.enable = cfg.enablePrompt;
    };
  })
    {
      ${top}.output = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable;
      lfs.enable = cfg.enableLFS;
      prompt.enable = cfg.enablePrompt;
    };
  };
    }
  ];
}
