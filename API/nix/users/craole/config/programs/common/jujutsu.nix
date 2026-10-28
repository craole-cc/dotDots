{user, ...}: {
  programs.jujutsu = {
    enable = true;
    settings.user = {inherit (user.git) name email;};
  };
}
