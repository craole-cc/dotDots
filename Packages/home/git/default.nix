{
  programs.git = {
    # enable = cfg.enable;
    # userName = cfg.user;
    # userEmail = cfg.email;
    lfs.enable = true;
    extraConfig = {
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
    includes = [
      # { path = "$RC_git"; }
      # { path = "~/path/to/config.inc"; }
      # {
      #   path = "~/path/to/conditional.inc";
      #   condition = "gitdir:~/src/dir";
      # }
    ];
  };
}
