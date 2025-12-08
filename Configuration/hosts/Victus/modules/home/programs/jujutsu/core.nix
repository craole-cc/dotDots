{ user, ... }:
{
  programs.jujutsu = {
    settings = {
      user = { inherit (user.git) name email; };
    };
  };
}
