{config, top, user, ...}: {
  programs.git = {
    enable = config.${top}.applications.utilities.git.enable;
    lfs.enable = true;
    settings = {
      user = {
        name = user.git.name or null;
        email = user.git.email or null;
      };
      core = {
        whitespace = "trailing-space,space-before-tab";
      };
      init = {
        defaultBranch = "main";
      };
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
    };
    includes = [];
  };
}
