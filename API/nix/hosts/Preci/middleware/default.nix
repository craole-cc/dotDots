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
    #? Both are passed as thunks from `packages`, for the reason the note above
    #? gives: a principal resolves its packages against these, and `packages`
    #? reads those resolutions back out as its `home` record.
    pkgs = packages.pkgs;
    sources = packages.sources;
  };

  packages = import ./packages.nix {inherit capabilities functionalities lix host principals inputs;};

  #? Which registry modules this host imports. `always` entries come along on
  #? every host; everything else is imported only when a principal's
  #? capabilities or packages, or the host's own packages, named it. The
  #? record is the single answer `modules/` filters imports through and a
  #? service module reads to decide whether to set its own `enable`.
  modules = import ./modules.nix {inherit lix host principals;};
in {
  inherit
    capabilities
    functionalities
    interface
    modules
    principals
    packages
    ;
}
