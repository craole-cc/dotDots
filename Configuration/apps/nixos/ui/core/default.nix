{
  config,
  specialArgs,
  ...
}:
let
  defaultUser = "craole";
  userName =
    if (specialArgs ? alpha) && (specialArgs.alpha != null) then specialArgs.alpha else defaultUser;
  user = if config.users.users ? userName then userName else throw "Unknown user: ${userName}";
in
{
  services.displayManager = {
    autoLogin = {
      enable = true;
      inherit user;
    };
  };
}
