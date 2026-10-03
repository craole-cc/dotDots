{
  lib ? import <nixpkgs/lib>,
  lix ? import ./libraries {inherit lib;},
  #? The raw host declaration, from `specs/`.
  specs ? import ./specs,
  #? The resolved host record. Derived from `specs` so a caller may pass either
  #? and get the same result; overridable to avoid resolving twice.
  host ? lix.schemas.host.mkHost specs,
  #? The resolution bundle, from `context/`.
  #?
  #? `host` is the resolved host record; `context` is the resolution boundary
  #? over it -- `data` (principals, packages, functionalities), `core`
  #? (host-level resolutions) and `home` (per-user selections).
  #?
  #? Modules read declarations from `host` and resolved values from `context`,
  #? so the two stay distinct: `host.interface.desktops` is what the host
  #? declared, `context.core.packages.kernel` is the derivation that name
  #? resolved to. The bundle is named for the directory it comes from, so the
  #? argument and its origin agree.
  context ? import ./context {inherit lix host;},
  ...
}: {
  #? The module tree is imported here rather than through an argument default.
  #?
  #? An argument default is only evaluated once the module system has decided
  #? what to pass, and deciding that requires `config` -- the very thing being
  #? built. So a default that reaches into `imports` makes the evaluator ask
  #? `_module.args` for an argument nobody supplied, which needs `config`, which
  #? recurses. Importing in the body avoids that entirely: the body is
  #? evaluated after the arguments are settled.
  #?
  #? `inherit` does not apply here: `imports` is not an alias of an argument
  #? but the contents of an imported module set.
  imports = (import ./modules {inherit lix;}).imports;

  _module.args = {
    inherit lix host context;

    #? `specs` is the raw declaration, kept for the modules that need it
    #? before resolution. Modules should prefer `host` or `context`.
    inherit specs;
  };
}
