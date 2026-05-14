_:
let
  app = "fish";
  isAllowed = false;
  # isAllowed = isIn app (
  #   (user.shells.system or user.shells.interactive or [])
  #   ++ user.applications.allowed or []
  #   ++ [user.interface.shell or null]
  # );
in
{
  programs.${app} = {
    enable = isAllowed;
  }
  // import ./settings.nix;
}
