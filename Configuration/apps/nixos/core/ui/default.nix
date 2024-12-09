{ specialArgs, ... }:
let
  name = if (specialArgs ? alpha) then specialArgs.alpha else null;
  display.autoLogin = true;
in
{
  services.displayManager.autoLogin = {
    enable = display.autoLogin && (name != null);
    user = name;
  };
}
