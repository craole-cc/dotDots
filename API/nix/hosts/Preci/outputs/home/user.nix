{host, infrastructure, user, ...}: {
  home.stateVersion = host.stateVersion;
  home.username = user.name;
  home.homeDirectory = user.paths.roots.home;

  home.packages = infrastructure.home.${user.name}.packages;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = user.git.name;
        email = user.git.email;
      };
    } // (user.git.settings or {});
  };
}
