{
  lix,
  #? The raw host declaration, as produced by `specs/`.
  specs ? null,
  #? The resolved host record. Derived from `specs` when not supplied, so a
  #? caller that already resolved it does not pay for a second resolution.
  host ? (
    if specs == null
    then throw "context: requires either 'host' (a resolved host) or 'specs' (a raw host declaration)"
    else lix.schemas.host.mkHost specs
  ),
  inputs ? lix.inputs or {},
  ...
}: let
  inherit (lix.attrsets) attrValues mapAttrs;
  inherit (lix.lists) concatLists foldl';
  inherit (lix.types.host.packages) resolvePackages;

  capabilities = import ./capabilities.nix {inherit lix inputs;};
  functionalities = import ./functionalities.nix {inherit lix host;};
  interface = import ./interface.nix {inherit lix host;};
  #? `packages.pkgs` is passed to `principals` rather than being built here,
  #? because the two need each other: `principals` resolves each user's
  #? packages against a package set, and `packages` reads those resolved
  #? packages back out as its `home` record.
  #?
  #? That reads as a cycle but is not one. Only `packages.pkgs` is required,
  #? and `pkgs` is derived from the host and the overlays alone -- it never
  #? looks at `principals`. Nix's laziness is what keeps it acyclic, so the
  #? argument is deliberately a thunk: forcing `principals` reaches `pkgs`,
  #? which resolves, and `packages` then reads `principals` back. If a future
  #? overlay ever depends on a principal's packages, this becomes a real cycle
  #? and the split has to become explicit.
  principals = import ./principals.nix {
    inherit lix host capabilities;
    inherit (packages) pkgs pools;
  };

  packages = import ./packages.nix {inherit lix host;};

  #? Which registry modules this host imports. `always` entries come along on
  #? every host; everything else is imported only when a principal's
  #? capabilities or packages, or the host's own packages, named it. The
  #? record is the single answer `modules/` filters imports through and a
  #? service module reads to decide whether to set its own `enable`.
  modules = import ./modules.nix {inherit lix host principals;};

  #? Merge contribution records of shape `{ packages; warnings; missing; }` --
  #? the shape every package resolver returns -- by concatenating each list
  #? field. `//` and `recursiveUpdate` would overwrite; only concatenation
  #? preserves every contributor. Unknown fields are dropped; add them here
  #? when a resolver grows one.
  mergeContributions = contributions:
    foldl'
    (acc: add: {
      packages = acc.packages ++ (add.packages or []);
      warnings = acc.warnings ++ (add.warnings or []);
      missing = acc.missing ++ (add.missing or []);
    })
    {
      packages = [];
      warnings = [];
      missing = [];
    }
    contributions;

  #? Host-level system packages: what the host spec declared, plus whatever
  #? future files contribute. Each contribution is a full resolver result, so
  #? a contributor only has to produce `{ packages; warnings; missing; }`.
  core = mergeContributions [
    (resolvePackages {
      inherit host;
      inherit (packages) pkgs pools;
    })
    # Future contributions to `core` land here.
  ];

  #? Per-principal packages, keyed by user name. One contribution per user for
  #? now; the merge is what lets a second file add to an existing user's list
  #? without replacing it.
  home =
    mapAttrs
    (_: principal: mergeContributions [principal.context.packages])
    principals;

  #? Findings as data, for a module to feed into NixOS `warnings`.
  #?
  #? Three sources, one list: the kernel's own warnings (from `resolve`), the
  #? host package resolver's warnings (absent names dropped), and each
  #? principal's package resolver warnings.
  warnings =
    packages.warnings
    ++ core.warnings
    ++ concatLists (map (hm: hm.warnings) (attrValues home));
in {
  inherit
    capabilities
    functionalities
    interface
    modules
    # principals
    ;
  inherit (packages) packages pkgs kernel;
  inherit core home warnings;
}
