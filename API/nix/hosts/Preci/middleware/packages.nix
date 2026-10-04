{
  lix,
  principals,
  host,
  ...
}: let
  inherit (lix) overlays;
  inherit (lix.attrsets) attrNames attrValues mapAttrs optionalAttrs;
  inherit (lix.lists) concatLists optional optionals;
  inherit (lix.modules) mkNixPkgs;
  inherit (lix.packages) mkSets;
  inherit (lix.strings) aliasOf concatStringsSep hasInfix toLower;
  inherit (lix.schemas.host.packages) resolveHostPackages;
  inherit (lix.schemas.host.kernel) bestFor describe levelOf isBetterThan unoptimised;
  inherit (host) cpu system; # TODO: move cpu out of specs, disolve specs

  forKernel = let
    #? The cachyOS kernels are not top-level nixpkgs attributes -- every
    #? `linux-cachyos-*` name lives in one attrset contributed by the loader,
    #? which has to be run to produce them.
    #?
    #? Running that loader builds all 96 kernels, so a host whose kernel is a
    #? plain nixpkgs name pays for 96 derivations it will never use. The
    #? loader is therefore gated on the declared name: a cachyOS kernel is
    #? prefixed `linux-cachyos-`, and only then is the loader consulted. The
    #? gate is on the *name*, not on a host declaration of its own, because
    #? `packages.kernel` is already the only statement of which kernel a host
    #? wants -- a separate `vendor = "cachyos"` field would be a second place to
    #? keep in step with it.
    defined = host.packages.kernel;

    #? A cachyOS kernel is any name mentioning `cachy` -- not only the
    #? `linux-cachyos-` prefix. `packages.kernel` may be spelled
    #? `cachyos`, `cachy`, `linux-cachyos-latest` or a full package-set entry,
    #? and all four mean the same source. Keying on the prefix would silently
    #? miss `cachy` and fall through to nixpkgs, where it does not exist, so
    #? the build would fail with a misleading "not found in nixpkgs".
    wantsCachyOS = hasInfix "cachy" (toLower defined) && unoptimised defined;

    #? The best variant this host can run, chosen from the ladder rather than
    #? hardcoded: the ladder is ordered best-first, so the ceiling is whatever
    #? the host's own declared kernel already asks for. A host declaring
    #? `cachyos` alone -- with no variant -- therefore lands on the unsuffixed
    #? build, which every CPU runs, instead of guessing `zen4` and producing a
    #? kernel that will not boot.
    #?
    #? An explicit variant in the declared name wins: if the author wrote
    #? `x86_64-v3`, that is a decision, not something to second-guess. Only a
    #? bare vendor request is completed for them.
    requested = optional wantsCachyOS (bestFor cpu);

    #? Every non-overlay source, resolved against `pkgs` once.
    #?
    #? `sources` here is the *resolved* source records, where every entry carries a
    #? `path`. The registry's own `sources` are only fetch specs, so a package-set
    #? or loader reading those would find `path` absent and fail on `null`. This is
    #? why `libraries/inputs/default.nix` exposes both: one to fetch from, one to
    #? read from.
    sets = mkSets {
      pkgs = mkNixPkgs {
        inherit system;
        overlays = optionals wantsCachyOS overlays.cachyos;
      };
    };

    #? Resolved only when the host asked for a cachyOS kernel. `null` otherwise,
    #? so the lookup below falls straight through to the package set instead of
    #? forcing the loader and building all 96 kernels.
    #?
    #? The loader is forced by `requested` when it is non-empty, because choosing
    #? a variant means reading the names it produced.
    kernels =
      optionalAttrs
      (wantsCachyOS && (requested != []))
      sets.loaders.cachyos-kernel;

    name = let
      join = parts: concatStringsSep "-" parts;
    in
      if requested == []
      then defined
      else join [defined (join requested)];
    # else "${defined}-${concatStringsSep "-" requested}";

    package = let
      err = "resolve host '${host.name}': kernel '${defined}' was found neither in the cachyOS loader nor in nixpkgs";
    in
      kernels.${name} or (pkgs.${name} or (throw err));

    #? The declared kernel's level, and the levels above it. `betterThan` is the
    #? ladder's own answer, so the ordering is never restated here.
    #?
    #? This only *reports*. Whether the host can execute a higher level depends
    #? on CPU flags, which no spec records -- `specs.cpu` declares `arch` and
    #? `brand` only, and brand alone cannot place a machine on the ladder. So the
    #? finding names the ladder rather than claiming a better kernel exists.
    level = levelOf defined;
    alternatives = isBetterThan level;

    #? Findings, bound before the result so neither is a multi-line expression the
    #? parser has to resolve precedence for. Written inline, `optionals … [ … ] ++
    #? concatLists …` evaluated to a two-element list whose second element was the
    #? pool attrset rather than the concatenated warnings.
    warnings = optionals (alternatives != []) [
      (describe {
        inherit level alternatives;
        kernel = defined;
      })
    ];
  in {inherit alternatives level name warnings;};
in {
  inherit pkgs;

  #? Host packages: the kernel above, plus whatever `host.packages` groups
  #? declare. These land in `environment.systemPackages`, so they must be
  #? available to every principal -- a bootloader tool or a kernel belongs to
  #? the machine, not to a user.
  #? The same pools and alias table the principals resolve against -- a host
  #? package that a fetched source publishes should resolve for the host too,
  #? rather than only for a user who asked for it.
  core = resolveHostPackages {
    inherit host pkgs aliasOf;
    pools = sets.packageSets;
  };

  #? Per-principal packages, keyed by user name.
  #?
  #? Read off `principals` rather than resolved again here: `principals.nix`
  #? already runs `resolvePackages {inherit user pkgs;}` per principal, using
  #? the *same* `pkgs` this file builds. Resolving a second time would produce
  #? an equal list at twice the evaluation cost, and two resolvers free to
  #? disagree. This file is the authority for `pkgs`; `principals.nix` is the
  #? authority for what each user gets.
  #?
  #? A module then reads `context.packages.home.<name>.packages` for one user
  #? and `context.core.packages` for the machine. Keeping them apart is the
  #? point: a user profile should carry that user's editor and terminal, not
  #? the kernel.
  home = mapAttrs (_: user: user.context.packages) principals;

  #? Every pool a package name may live in, keyed by source. Exported so
  #? `context/principals.nix` resolves a user's names against the same pools,
  #? rather than against nixpkgs alone -- which is what made `hermes` throw
  #? while the source publishing it sat pinned in the registry.
  sources = sets.packageSets;

  #? The imbued kernel record: what the host declared, what it resolved to, and
  #? what the ladder says sits above it.
  kernel = {
    inherit package level alternatives;
    name = kernel;
  };

  #? Findings as data, for a module to feed into NixOS `warnings` -- which
  #? reaches the build log, unlike `builtins.trace`.
  warnings =
    forKernel.warnings
    ++
    #? Names a principal asked for that no pool carried. Collected from the
    #? per-user resolutions, so each message names the user who asked.
    concatLists (
      map
      (name: (principals.${name}.context.packages.warnings or []))
      (attrNames principals)
    );
}
