{
  host,
  lix,
  ...
}: let
  inherit (host.principals) primary;
  inherit (lix.lists) head;

  #? `git` is a *list* of identity profiles, not an attrset. The first entry is
  #? the primary identity.
  gitProfiles = primary.git or [];
  primaryGit =
    if gitProfiles == []
    then {}
    else head gitProfiles;
in {
  programs = {
    bash.enable = true;
    dconf.enable = true;
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config =
        {
          #? `programs.git.config` is `either gitini (listOf gitini)`: the
          #? *whole* config may be a list of ini sets, but `user` itself stays
          #? an attrset. Wrapping `user` in a list would be read as a second
          #? ini document, not a second user.
          user = {
            inherit (primaryGit) name email;
          };
          init.defaultBranch = "main";
          safe.directory = [host.paths.roots.src];
          url."https://github.com/".insteadOf = ["gh:" "github:"];
        }
        // (primaryGit.settings or {});
    };
    nh = {
      enable = true;
      clean.enable = true;
      flake = host.paths.roots.src;
    };
    nix-index.enable = true;
    nix-index-database = {
      enable = true;
      comma.enable = true;
    };
    starship.enable = true;
  };
}
