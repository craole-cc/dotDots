{
  lib,
  lix,
  user,
  inputs,
  ...
}: let
  app = "starship";
  opt = [app "starship-prompt" "starship-rs"];
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;
  inherit (lix.lists.predicates) isIn;

  isAllowed = isIn opt (
    (user.applications.allowed or [])
    ++ [(user.interface.prompt or null)]
  );
in {
  config = mkIf isAllowed {
    programs.${app} =
      {enable = true;}
      // import ./settings.nix;

    # home.file.".config/starship.toml" = {
    #   source = src + "/Configuration/starship/config.toml";
    # };
  };
}
