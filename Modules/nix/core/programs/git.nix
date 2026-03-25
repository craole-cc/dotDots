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
    lfs = mkTrue "Large File Storage for Git";
    prompt = mkTrue "Utility functions via `git-prompt.sh`";
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
    };
  };
}
