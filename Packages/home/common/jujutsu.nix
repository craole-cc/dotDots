{user, ...}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = user.git.name or null;
        email = user.git.email or null;
      };
    };
  };
}
