{config, lib, lix, top, user, ...}: let
  inherit (lix.modules.core.staging) mkStaged;

  payload = {
    programs.git = {
      enable = config.${top}.resolved.applications.utilities.git.enable;
      lfs.enable = true;
      settings = {
        user = {
          name = user.git.name or null;
          email = user.git.email or null;
        };
        core.whitespace = "trailing-space,space-before-tab";
        init.defaultBranch = "main";
        url."https://github.com/".insteadOf = ["gh:" "github:"];
      };
      includes = [];
    };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
