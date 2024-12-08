{ env, ... }:
let
  currentUser = builtins.getEnv "USER";
  defaultUser = "craole";
  # user = defaultUser;
  # user = if currentUser != "" then currentUser else defaultUser;
  user = currentUser;
in
{
  displayManager = {
    autoLogin = {
      enable = true;
      inherit user;
    };
  };
}
