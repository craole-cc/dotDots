{
  lib,
  user,
  ...
}: let
  app = "jujutsu";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app} = {
    enable = isAllowed;
    settings = {
      user = {inherit (user.git) name email;};
    };
  };
}
