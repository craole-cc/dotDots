{lib, ...}: let
  inherit (lib.attrsets) attrByPath optionalAttrs;
  inherit (lib.lists) filter head;
  inherit (lib.strings) concatStringsSep;

  # Evaluate a fetched tree as a flake. The tree must carry a narHash
  # (which fetchTree provides) so getFlake can run in pure mode with a
  # locked reference -> no warning, no --impure.
  # `builtins.getFlake` is unavailable in older Nix versions, so guard the
  # lookup and fail with a clear message instead of crashing at parse time.
  getFlake = tree:
    if builtins ? getFlake
    then let
      inherit (builtins) getFlake unsafeDiscardStringContext;
      inherit (tree) narHash outPath;
      path = unsafeDiscardStringContext outPath;
    in
      getFlake "path:${path}?narHash=${narHash}"
    else throw "fetchers.getFlake: builtins.getFlake is unavailable in this Nix build";

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
  # Fetch a source spec into a { outPath, narHash, ... } tree. Accepts
  # either `sha256` (canonical) or `hash` (used by fetchFromGitHub-style
  # specs). Falls back to an unlocked fetch only if neither is set.
  fetchSource = source: let
    narHash = source.sha256 or source.hash or null;
    inherit (source) url;
    type = "tarball";
  in
    if narHash != null
    then fetchTree {inherit narHash type url;}
    else fetchTree {inherit type url;};

  # Materialize a source spec into a resolved record. Downstream
  # consumers rely on:
  #   .tree  -> the fetchTree result, with narHash
  #   .path  -> tree.outPath (string), for imports and NIX_PATH
  #   .value -> the evaluated flake when flake = true, else tree.outPath
  materializeSource = source: let
    tree = fetchSource source;
    isFlake = source.flake or false;
  in
    source
    // {
      inherit tree;
      path = tree.outPath;
      value =
        if isFlake
        then getFlake tree
        else tree.outPath;
    };

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
    flake ? false,
    type ? "github",
  }: {
    inherit type owner repo rev sha256 flake;
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
  };

  /**
  Resolve a NixOS module by name, preferring a live flake input over a
  pinned fallback source.

  Resolution order:
    1. If `enabled` is `false`, return `{}` (a valid, inert module).
    2. If `name` exists in `inputs`, use its `nixosModules.${name}` output,
       or the input itself if it has no such output (e.g. it *is* the module).
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
    class ? "nixos",
    outputs ? null,
    default ? null,
    enabled ? true,
    inputs ? lib.flakes.inputs or null,
    sources,
  }: let
    ctx = "fetchModule";
    # Resolution order for a flake input:
    #   1. Explicit `outputs` attr path, if given (throws if missing).
    #   2. `<namespace>.<name>` — the conventional name-matched export.
    #   3. `<namespace>.default` — the default-export convention.
    #   4. The flake itself — for flakes that ARE a module.
    #
    # Lazy: `namespace` is only forced when `outputs` is null, so callers
    # passing an explicit `outputs` never trip the class validation.
    candidates =
      if outputs != null
      then [outputs]
      else let
        namespace =
          {
            nixos = "nixosModules";
            homeManager = "homeManagerModules";
          }.${
            class
          } or (throw "${ctx}: unsupported class '${class}'");
      in [
        [namespace name]
        [namespace "default"]
        []
      ];

    fromFlake = flake: let
      try = path: attrByPath path null flake;
    in
      if outputs != null
      then let
        value = try outputs;
      in
        if value != null
        then value
        else
          throw "${ctx}: '${name}' does not export ${
            concatStringsSep "." outputs
          }"
      else let
        hits = filter (path: (try path) != null) candidates;
      in
        if hits != []
        then try (head hits)
        else null;

    raw = sources.${name} or null;
    # Accept either a resolved source (from `resolve`) or a bare spec.
    # Resolved sources carry `.fromFlake`, which is our marker.
    source =
      if raw == null
      then null
      else if raw ? fromFlake
      then raw
      else materializeSource raw;

    isFlakeInput = inputs != null && inputs ? ${name};

    flake =
      if source == null || !(source.flake or false)
      then null
      else source.value;

    module =
      if flake != null
      then fromFlake flake
      else null;
  in
    optionalAttrs enabled (
      if isFlakeInput
      then fromFlake inputs.${name}
      else if source != null
      then
        if module != null
        then module
        else if path != null
        then import "${source.path}/${path}"
        else if default != null
        then default source.path
        else throw "${ctx}: no module resolved for '${name}'"
      else throw "${ctx}: '${name}' is neither a flake input nor a pinned source"
    );
in {
  inherit
    fetchModule
    fetchSource
    materializeSource
    mkGitHubSource
    ;
}
