{
  env ? "hyprland",
  autoLogin ? {
    enable = true;
    user =
      let
        currentUser = builtins.getEnv "USER";
        defaultUser = "craole";
        # user = defaultUser;
        # user = if currentUser != "" then currentUser else defaultUser;
        user = currentUser;
      in
      currentUser;
  },
  ...
}:
let
  ui =
    if env == "plasma" then
      (import ./plasma.nix)
    else if env == "xfce" then
      (import ./xfce.nix)
    else
      (import ./hyprland.nix);
in
{
  # imports = [ ui ];
  displayManager = {
    # autoLogin = {
    #   inherit (autoLogin) enable user;
    # };
  };
}
