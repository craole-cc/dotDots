_: let
  app = "zsh";
  isAllowed = false;
  # isAllowed = isIn app (
  #   (user.shells or [])
  #   ++ user.applications.allowed or []
  #   ++ [user.interface.shell or null]
  # );
in {
  programs.${app} =
    {
      enable = isAllowed;
    }
    // import ./settings.nix;
}
