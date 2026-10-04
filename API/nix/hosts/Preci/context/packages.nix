{
  lix,
  principals,
  host,
  ...
}: let
  inherit (lix) overlays;
  inherit (lix.attrsets) attrValues mapAttrs optionalAttrs;
  inherit (lix.lists) optionals;
  inherit (lix.modules) mkNixPkgs;
  inherit (lix.packages) mkSets;
  inherit (lix.schemas.host.packages) resolveHostPackages;
  inherit (lix.strings) concatStringsSep hasInfix;

  #? Bound whole rather than destructured: `kernel.nix` exports both the
  #? ladder *data* (`levels`, `variants`) and the functions over it
  #? (`levelOf`, `isBetterThan`). Inheriting `levels` alone would bind the
  #? list and leave `levels.levelOf` undefined, which reads as a list wherever
  #? a level name was expected.
  vocabulary = lix.schemas.host.kernel;

  #? `lix.inputs` entries are *source records* (owner/rev/path/...), not
  #? package sets. Reading `inputs.nixpkgs.<pkg>` looks the attribute up on that
  #? record, which has no packages on it, so every resolution silently misses.
  #? The package set comes from importing the pinned source at `.path`.
  #?
  #? Built with `mkNixPkgs` rather than a bare `import` so the host's overlays
  #? are applied: `rust-overlay` is what makes `rust-bin` available, and a
  #? capability requesting nightly Rust resolves through it.
  #? `overlays` hangs off `lix` itself, not `lix.inputs`: `libraries/inputs/`
  #? resolves them from the registry and exposes them as a sibling of the
  #? source records. `lix.inputs` is the source records themselves.
  pkgs = mkNixPkgs {
    inherit (host) system;
    overlays = attrValues overlays;
  };

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
  inherit (host.packages) kernel;

  #? A cachyOS kernel is any name mentioning `cachy` -- not only the
  #? `linux-cachyos-` prefix. `packages.kernel` may be spelled
  #? `cachyos`, `cachy`, `linux-cachyos-latest` or a full package-set entry,
  #? and all four mean the same source. Keying on the prefix would silently
  #? miss `cachy` and fall through to nixpkgs, where it does not exist, so
  #? the build would fail with a misleading "not found in nixpkgs".
  cachy = hasInfix "cachy" kernel;

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
  requested =
    optionals (cachy && vocabulary.unoptimised kernel) [
      (vocabulary.bestFor host.specs.cpu)
    ];

  #? Resolved only when the host asked for a cachyOS kernel. `null` otherwise,
  #? so the lookup below falls straight through to the package set instead of
  #? forcing the loader and building all 96 kernels.
  #?
  #? The loader is forced by `requested` when it is non-empty, because choosing
  #? a variant means reading the names it produced.
  kernels =
    optionalAttrs
    (cachy && (requested != [] || !vocabulary.unoptimised kernel))
    (mkSets {
      inherit pkgs;
      #? `sources` is the *resolved* source records, where every entry carries a
      #? `path`. The registry's own `sources` are only fetch specs, so a loader
      #? reading those would find `path` absent and fail on `null`. This is why
      #? `libraries/inputs/default.nix` exposes both: one to fetch from, one to
      #? read from.
      sources = lix.inputs;
    }).loaders.cachyos-kernel;

  name = if requested == [] then kernel else "${kernel}-${concatStringsSep "-" requested}";

  package = let
    err = "resolve host '${host.name}': kernel '${kernel}' was found neither in the cachyOS loader nor in nixpkgs";
  in
    kernels.${name} or (pkgs.${name} or (throw err));

  #? The declared kernel's level, and the levels above it. `betterThan` is the
  #? ladder's own answer, so the ordering is never restated here.
  #?
  #? This only *reports*. Whether the host can execute a higher level depends
  #? on CPU flags, which no spec records -- `specs.cpu` declares `arch` and
  #? `brand` only, and brand alone cannot place a machine on the ladder. So the
  #? finding names the ladder rather than claiming a better kernel exists.
  level = vocabulary.levelOf kernel;

  alternatives = vocabulary.isBetterThan level;
in {
  inherit pkgs;

  #? Host packages: the kernel above, plus whatever `host.packages` groups
  #? declare. These land in `environment.systemPackages`, so they must be
  #? available to every principal -- a bootloader tool or a kernel belongs to
  #? the machine, not to a user.
  core = resolveHostPackages {inherit host pkgs;};

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

  #? The imbued kernel record: what the host declared, what it resolved to, and
  #? what the ladder says sits above it.
  kernel = {
    inherit package level alternatives;
    name = kernel;
  };

  #? Findings as data, for a module to feed into NixOS `warnings` -- which
  #? reaches the build log, unlike `builtins.trace`.
  #?
  #? The call is parenthesised because `f\n{…}` inside a list parses as two
  #? elements -- the function and the attrset -- not as one application, so
  #? the warning would be a `[lambda, set]` pair instead of a string. The
  #? same split applies to `inherit`: `describe` takes `kernel`, which is the
  #? local string here.
  warnings = optionals (alternatives != []) [
    (vocabulary.describe {inherit kernel level alternatives;})
  ];
}
