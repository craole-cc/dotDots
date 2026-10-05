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

  #? ── Shared ──────────────────────────────────────────────────────────────
  #? What both tools read: the principal's profiles, who they are, and where
  #? their repos live. Anything used by only one tool belongs in its own scope
  #? below.
  userGit = user.git or {};

  #? Whether this principal gets the git toolchain at all. Read from the
  #? principal's data, never from `config.programs.*.enable`: Home Manager's
  #? tool modules (delta, diff-so-fancy, ...) set `programs.git` themselves, so
  #? gating one on another's `enable` makes the option system chase its own
  #? tail and fail with infinite recursion.
  enable = userGit.enable or true;

  profiles = userGit.profiles or [];
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

  #? ── Git ─────────────────────────────────────────────────────────────────
  git = let
    #? One conditional include per profile: any repo under the profile's root
    #? commits as that identity.
    includeOf = profile: {
      condition = "gitdir:${projectOf profile}/";
      contents = identityOf profile;
    };

    #? A repo whose remote lives under the profile's GitHub owner commits as that
    #? identity, wherever it is cloned. Case-sensitive; https remotes only.
    remoteIncludeOf = profile: {
      condition = "hasconfig:remote.*.url:https://github.com/${profile.root}/**";
      contents = identityOf profile;
    };

    extraIncludeOf = extraRoot: {
      condition = "gitdir:${extraRoot.path}/";
      contents = identityOf extraRoot.profile;
    };
  in {
    includes =
      map includeOf profiles
      ++ map remoteIncludeOf profiles
      ++ map extraIncludeOf extraRoots;
    settings = (userGit.settings or {}) // fallbackIdentity;
  };

  #? ── Jujutsu ─────────────────────────────────────────────────────────────
  jujutsu = let
    #? A settings scope that applies only to repositories under the given path.
    scopeAt = path: profile:
      {"--when".repositories = [path];}
      // identityOf profile;

    scopeOf = profile: scopeAt (projectOf profile) profile;
    extraScopeOf = extraRoot: scopeAt extraRoot.path extraRoot.profile;
  in {
    settings =
      fallbackIdentity
      // optionalAttrs hasProfiles {
        "--scope" = map scopeOf profiles ++ map extraScopeOf extraRoots;
      };
  };
in {
  programs = {
    git = {
      inherit enable;
      lfs.enable = true;
      inherit (git) includes settings;
    };

    jujutsu = {
      inherit enable;
      inherit (jujutsu) settings;
    };

    #? delta is the pager for both git and jujutsu. diff-so-fancy stays installed
    #? but is not wired into git: both would set `core.pager`, and two definitions
    #? of the same git option fail the build.
    delta = {
      inherit enable;
      enableGitIntegration = enable;
      enableJujutsuIntegration = enable;
      options = {
        navigate = true;
        line-numbers = true;
      };
    };

    diff-so-fancy = {
      inherit enable;
      enableGitIntegration = false;
    };

    gitui = {
      inherit enable;
    };

    gh = {
      inherit enable;
      gitCredentialHelper.enable = true;
      settings.git_protocol = "https";
    };

    gh-dash = {
      inherit enable;
    };
  };
}
