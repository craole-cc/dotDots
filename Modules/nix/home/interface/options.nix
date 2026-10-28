{
  user,
  lix,
  top,
  ...
}: let
  inherit (lix.attrsets.transformation) removeAttrs;
in {
  # mkUsers enriches each user with an already-normalized interface. Expose
  # that schema result to Home exactly once so mkContext consumers share the
  # same resolved contract as Core without re-normalising host/user data.
  # The wallpaper component owns its explicit and implicit namespaces.
  options.${top}.resolved.interface = removeAttrs (lix.schema.ui.mkOptions {
    ui = user.interface;
  }) ["wallpaper"];
}
