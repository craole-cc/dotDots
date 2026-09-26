{...}: let
  /**
  Build a fetch spec for a GitHub archive tarball.

  Takes GitHub coordinates and returns the attrset `fetchSource` expects: a
  `url` pointing at the commit archive, plus the inputs echoed back for
  introspection (so callers/debug tooling can see what was requested
  without re-deriving it from the url).

  # Inputs

  `owner`
  : GitHub org/user. String.

  `repo`
  : Repository name. String.

  `rev`
  : Commit hash to pin to — not a branch name; a branch's tarball changes
    under a fixed hash, so `rev` must be a commit for reproducibility.
    String.

  `sha256`
  : Fixed-output hash for reproducibility, or `null` to fetch unpinned.
    Nullable string. Default `null`.

  `type`
  : Source kind, echoed through for downstream consumers (e.g. flake input
    classification). Does not currently affect URL construction — only
    GitHub-shaped archive URLs are built regardless of this value.
    String. Default `"github"`.

  # Type

  ```
  mkGitHubSource :: {
    owner : String,
    repo : String,
    rev : String,
    sha256 : String | null ? null,
    type : String ? "github",
  } -> {
    type : String,
    owner : String,
    repo : String,
    rev : String,
    sha256 : String | null,
    url : String,
  }
  ```

  # Example

  ```nix
  mkGitHubSource {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "abc123...";
    sha256 = "sha256-...=";
  }
  # => { type = "github"; owner = "nixos"; repo = "nixpkgs"; rev = "abc123..."; sha256 = "sha256-...="; url = "https://github.com/nixos/nixpkgs/archive/abc123....tar.gz"; }
  ```
  */
  mkGitHubSource = {
    owner,
    repo,
    rev,
    sha256 ? null,
    type ? "github",
  }: {
    inherit type owner repo rev sha256;
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
  };

  /**
  Fetch a tarball from a source spec (as produced by `mkGitHubSource`).

  Reproducible when `sha256` is set: uses `fetchTarball { url; sha256; }`,
  which Nix can verify and cache without network access on a hash match.
  Falls back to an unpinned `fetchTarball url` when `sha256` is `null` or
  empty — convenient for local iteration, but not reproducible and always
  hits the network.

  # Inputs

  `src`
  : A source spec attrset with at least `url`, and optionally `sha256`.

  # Type

  ```
  fetchSource :: { url : String, sha256 : String | null, ... } -> Path
  ```

  # Example

  ```nix
  fetchSource (mkGitHubSource { owner = "nixos"; repo = "nixpkgs"; rev = "abc123..."; })
  ```
  */
  fetchSource = src:
    if src ? sha256 && src.sha256 != null && src.sha256 != ""
    then fetchTarball {inherit (src) url sha256;}
    else fetchTarball src.url;

  /**
  Resolve a NixOS module by name, preferring a live flake input over a
  pinned fallback source.

  Resolution order:
    1. If `enabled` is `false`, return `{}` (a valid, inert module).
    2. If `name` exists in `inputs`, use its `nixosModules.${name}` output,
       or the input itself if it has no such output (e.g. it *is* the
       module).
    3. Otherwise, fetch `sources.${name}` via `fetchSource` and either
       `import` it at `path`, or hand the fetched store path to `default`.

  Both `inputs` (live flake inputs) and `sources` (pinned fallbacks) are
  taken as explicit parameters rather than captured from enclosing scope,
  so this function stays pure and reusable outside this file.

  # Inputs

  `name`
  : Key into both `inputs` and `sources`. String.

  `path`
  : Subpath to `import` from the fetched source, relative to its root.
    Takes precedence over `default` when both could apply.
    Nullable string. Default `null`.

  `default`
  : Function applied to the fetched store path when `path` is not given.
    Nullable function `Path -> a`. Default `null`.

  `enabled`
  : Set `false` to skip resolution entirely and return `{}`. Bool.
    Default `true`.

  `inputs`
  : Live flake inputs to check first, keyed by name. Attrset. Default `{}`.

  `sources`
  : Pinned fallback fetch specs, keyed by name, as produced by
    `mkGitHubSource` (or an equivalent hand-built spec). Attrset.
    Default `{}`.

  # Type

  ```
  fetchModule :: {
    name : String,
    path : String | null ? null,
    default : (Path -> a) | null ? null,
    enabled : Bool ? true,
    inputs : AttrSet ? {},
    sources : AttrSet ? {},
  } -> AttrSet | a
  ```

  # Example

  ```nix
  fetchModule {
    name = "home-manager";
    path = "nixos";
    inherit inputs sources;
  }
  ```
  */
  fetchModule = {
    name,
    path ? null,
    default ? null,
    enabled ? true,
    inputs ? {},
    sources ? {},
  }:
    if !enabled
    then {} #? Returns an empty valid module!
    else if inputs ? ${name}
    then inputs.${name}.nixosModules.${name} or inputs.${name}
    else let
      fetched = fetchSource sources.${name};
    in
      if path != null
      then import "${fetched}/${path}"
      else default fetched;
in {inherit mkGitHubSource fetchSource fetchModule;}
