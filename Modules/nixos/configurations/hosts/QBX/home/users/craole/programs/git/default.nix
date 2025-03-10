{
  imports = [];

  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Craole";
    userEmail = "32288735+Craole@users.noreply.github.com";
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
