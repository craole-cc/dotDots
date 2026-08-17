{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "git";
  };
  inherit (context) cfg mod;
  inherit (lix.options.construction) mkTrue;
  inherit (lix.modules.construction) mkConfig mkContext;
in
  mkConfig {
    inherit context;
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
