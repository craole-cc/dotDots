#? Git and its companion tools for one principal, as Home Manager programs.
#?
#? `user` is the resolved principal for this profile, injected by `users.nix`.
#? `user.git.profiles` is a list of identities. Each one selects its identity
#? three ways, so a repo commits as that identity in git and jujutsu alike:
#?
#?   directory  any repo under ~/Projects/<root>/ (git and jujutsu).
#?   remote     any repo whose remote lives under github.com/<root>/, wherever
#?              it is cloned (git only; jujutsu has no remote condition).
#?   explicit   repos outside ~/Projects, such as the dotDots clone, named by
#?              `paths.roots.repo` (git and jujutsu).
#?
#? The first profile also seeds the global identity as a fallback.
{
  config,
  lix,
  paths,
  user,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.lists) filter head;
  inherit (lix.strings) mkPath;

  cfg = {
    git = config.programs.git;
    jujutsu = config.programs.jujutsu;
    hasGit = cfg.git.enable;
    hasJJ = cfg.jujutsu.enable;
  };

  git = user.git or {};
  profiles = git.profiles or [];
  hasProfiles = profiles != [];

  identityOf = profile: {user = {inherit (profile) name email;};};
  fallbackIdentity = optionalAttrs hasProfiles (identityOf (head profiles));

  projectOf = profile:
    mkPath config.home.homeDirectory ["Projects" profile.root];

  #? Repos that live outside ~/Projects/<root>/ and so cannot be found by
  #? directory convention. The dotDots clone belongs to the `craole-cc` profile.
  #? `toString` keeps the path a plain string: interpolating a Nix path value
  #? would copy it into the store.
  extraRoots =
    map (profile: {
      path = toString paths.roots.repo;
      inherit profile;
    })
    (filter (profile: profile.root == "craole-cc") profiles);

  #? One conditional include per profile: any repo under the profile's root
  #? commits as that identity.
  gitIncludeOf = profile: {
    condition = "gitdir:${projectOf profile}/";
    contents = identityOf profile;
  };

  #? A repo whose remote lives under the profile's GitHub owner commits as that
  #? identity, wherever it is cloned. Case-sensitive; https remotes only.
  gitRemoteIncludeOf = profile: {
    condition = "hasconfig:remote.*.url:https://github.com/${profile.root}/**";
    contents = identityOf profile;
  };

  gitExtraIncludeOf = extraRoot: {
    condition = "gitdir:${extraRoot.path}/";
    contents = identityOf extraRoot.profile;
  };

  #? The jujutsu equivalent: a settings scope that applies only to repositories
  #? under the given path.
  jujutsuScopeAt = path: profile:
    {"--when".repositories = [path];}
    // identityOf profile;

  jujutsuScopeOf = profile: jujutsuScopeAt (projectOf profile) profile;
  jujutsuExtraScopeOf = extraRoot:
    jujutsuScopeAt extraRoot.path extraRoot.profile;
in {
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      includes =
        map gitIncludeOf profiles
        ++ map gitRemoteIncludeOf profiles
        ++ map gitExtraIncludeOf extraRoots;
      settings = (git.settings or {}) // fallbackIdentity;
    };

    jujutsu = {
      enable = cfg.hasGit;
      settings =
        fallbackIdentity
        // optionalAttrs hasProfiles {
          "--scope" =
            map jujutsuScopeOf profiles
            ++ map jujutsuExtraScopeOf extraRoots;
        };
    };

    #? delta is the pager for both git and jujutsu. diff-so-fancy stays installed
    #? but is not wired into git: both would set `core.pager`, and two definitions
    #? of the same git option fail the build.
    delta = {
      enable = cfg.hasGit;
      enableGitIntegration = cfg.hasGit;
      enableJujutsuIntegration = cfg.hasJJ;
      options = {
        navigate = true;
        line-numbers = true;
      };
    };

    diff-so-fancy = {
      enable = cfg.hasGit;
      enableGitIntegration = false;
    };

    gitui.enable = cfg.hasGit;

    gh = {
      enable = cfg.hasGit;
      gitCredentialHelper.enable = true;
      settings.git_protocol = "https";
    };

    gh-dash.enable = cfg.hasGit;
  };
}
