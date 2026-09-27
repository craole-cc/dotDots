lib: let
  default =
    {
      #? Must be defined by the host
      name = null;
      role = null;
      enable = true;
      autoLogin = false;
    }
    // (import ./applications.nix)
    // (import ./capabilities.nix)
    // (import ./git.nix)
    // (import ./interface.nix)
    // (import ./paths.nix)
    // {
      description = null;
      password = null;
      hashedPassword = null;
      localization = {}; #? Default to host definition
    };
in
  (import ./lib.nix (lib // {inherit default;}))
  // {user = default;}
