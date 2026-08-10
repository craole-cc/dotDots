{config, lib, lix, top, user, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs.jujutsu = {
        enable = config.${top}.inputs.applications.utilities.jujutsu.enable;
        settings = {
          user = {
            name = user.git.name or null;
            email = user.git.email or null;
          };
        };
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
