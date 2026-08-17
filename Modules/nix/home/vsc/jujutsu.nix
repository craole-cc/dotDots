{
  config,
  lix,
  top,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig;
  payload = {
    programs.jujutsu = {
      enable = config.${top}.resolved.applications.utilities.jujutsu.enable;
      settings = {
        user = {
          name = user.git.name or null;
          email = user.git.email or null;
        };
      };
    };
  };
in
  mkConfig {inherit payload;}
