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
  inherit (lix.lists) head;

  #? `git` is a *list* of identity profiles, not an attrset. The first entry is
  #? the primary identity, so its `name`/`email` seed the global git config and
  #? the rest are exposed as conditional includes by the NixOS-side module.
  gitProfiles = user.git or [];
  primaryGit = if gitProfiles == [] then {} else head gitProfiles;
in {
  home = {
    inherit (host) stateVersion;
    username = user.name;
    homeDirectory = user.paths.roots.home;
    packages = context.home.${user.name}.packages;
  };

  programs.git = {
    enable = true;
    settings =
      {
        user = {
          inherit (primaryGit) name email;
        };
      }
      // (primaryGit.settings or {});
  };
}