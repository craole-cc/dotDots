{user, ...}: {
  programs.git = {
    lfs.enable = true;
    settings = {
      user = {inherit (user.git) name email;};
      core = {
        whitespace = "trailing-space,space-before-tab";
      };
      init = {
        defaultBranch = "main";
      };
      url = {
        "https://github.com/" = {insteadOf = ["gh:" "github:"];};
      };
    };
  };
}
