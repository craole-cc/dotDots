{
  config,
  lib,
  user,
  lix,
  src,
  ...
}: let
  app = "starship";
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;

  isAllowed = isIn app (
    (user.applications.allowed or [])
    ++ [(user.interface.prompt or null)]
  );
in {
  config = mkIf isAllowed {
    programs.${app} = {
      enable = isAllowed;
      enableBashIntegration = config.programs.bash.enable;
      enableNushellIntegration = config.programs.nushell.enable;
    };

    #> Link the config file from your dots directory
    home.file.".config/starship.toml" = {
      source = src + "/Configuration/starship/config.toml";
    };
  };
}
