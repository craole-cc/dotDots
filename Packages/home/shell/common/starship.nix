{
  lib,
  user,
  inputs,
  ...
}: let
  app = "starship";
  opt = [app "starship-prompt" "starship-rs"];
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;

  isAllowed = isIn opt (
    (user.applications.allowed or [])
    ++ [(user.interface.prompt or null)]
  );
in {
  config = mkIf isAllowed {
    programs.${app} =
      {enable = true;}
      // import ./settings.nix;
  };
}
