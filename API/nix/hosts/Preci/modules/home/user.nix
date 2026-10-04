#? Per-principal Home Manager configuration.
#?
#? `user` is the resolved principal for this profile, injected by `users.nix`.
{
  context,
  host,
  lix,
  user,
  ...
}: let
  # inherit (lix.attrsets) optionalAttrs;
  inherit (lix.lists) head;

  #? `git` is a *list* of identity profiles, not an attrset. The first entry is
  #? the primary identity, so its `name`/`email` seed the global git config and
  #? the rest are exposed as conditional includes by the NixOS-side module.
  # TODO: If this is home what were we setting git only to the primary, we should be defining all the profiles
  git = let
    profiles = user.git or [];
  in
    #TODO: Should we use optionalAttrs here?
    if profiles != []
    then head profiles
    else {};
in {
  home = {
    inherit (host) stateVersion;
    username = user.name;
    homeDirectory = user.paths.roots.home;
    packages = context.home.${user.name}.packages;
  };

  programs = {
    git = {
      enable = true;
      settings =
        # TODO: We should have a default set of settings, are they defined in the schema or context?
        (git.settings or {})
        // {user = {inherit (git) name email;};};
    };
  };
}
