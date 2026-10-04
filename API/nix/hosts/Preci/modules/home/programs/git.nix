#? Git and its companion tools for one principal, as Home Manager programs.
#?
#? `user` is the resolved principal for this profile, injected by
#? `modules/home/default.nix` as `_module.args.user`.
#? `user.git.profiles` is a list of identities. Each one becomes a conditional
#? include for git and a scoped override for jujutsu, so a repo under
#? ~/Projects/<root>/ commits as that identity in either tool. The first profile
#? also seeds the global identity as a fallback.
{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.lists) head;
  inherit (lix.strings) mkPath;

  git = user.git or {};
  profiles = git.profiles or [];

  hasGit = config.programs.git.enable;
  hasProfiles = profiles != [];

  identityOf = profile: {user = {inherit (profile) name email;};};
  fallbackIdentity = optionalAttrs hasProfiles (identityOf (head profiles));

  projectsOf = profile:
    mkPath config.home.homeDirectory [
      "Projects"
      "${profile.root}"
    ];

  #? One conditional include per profile: any repo under the profile's root
  #? commits as that identity.
  gitIncludeOf = profile: {
    condition = "gitdir:${projectsOf profile}/";
    contents = identityOf profile;
  };

  #? The jujutsu equivalent: a settings scope that applies only to repositories
  #? under the profile's root.
  jujutsuScopeOf = profile:
    {"--when".repositories = [(projectsOf profile)];}
    // identityOf profile;
in {
  programs = {
    git = {
      enable = true;
      lfs.enable = hasGit;
      includes = map gitIncludeOf profiles;
      settings = (git.settings or {}) // fallbackIdentity;
    };

    jujutsu = {
      enable = hasGit;
      settings =
        fallbackIdentity
        // optionalAttrs hasProfiles {"--scope" = map jujutsuScopeOf profiles;};
    };

    diff-so-fancy = {
      enable = hasGit;
      enableGitIntegration = hasGit;
    };

    gitui.enable = hasGit;
    gh.enable = hasGit;
  };
}
