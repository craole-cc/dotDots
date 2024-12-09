{ specialArgs, ... }:
let
  name = if (specialArgs ? alpha) then specialArgs.alpha else null;
  login = if (specialArgs.ui ? autoLogin) then specialArgs.ui.autoLogin else true;
in
{
  services.displayManager.autoLogin = {
    enable = login && (name != null);
    user = name;
  };
}
