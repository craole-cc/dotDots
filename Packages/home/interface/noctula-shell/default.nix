{
  lib,
  user,
  inputs,
  ...
}: let
  app = "noctalia-shell";
  opt = [app "noctalia"];
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;

  isAllowed = isIn opt (
    (user.applications.allowed or [])
    ++ [(user.interface.bar or null)]
  );
in {
  config = mkIf isAllowed {
    programs = {
      ${app} =
        {enable = true;}
        // import ./settings.nix;

      waybar.enable = mkForce false;
    };
  };
}
