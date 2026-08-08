{config, top, user, ...}: {
  programs.jujutsu = {
    enable = config.${top}.applications.utilities.jujutsu.enable;
    settings = {
      user = {
        name = user.git.name or null;
        email = user.git.email or null;
      };
    };
  };
}
