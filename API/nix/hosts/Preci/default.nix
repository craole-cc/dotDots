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
  #? The NixOS/Home Manager module tree.
  modules ? (import ./modules {inherit lix;}),
  ...
}: {
  imports = [modules];

  _module.args = {
    inherit lix host context;

    #? `specs` is the raw declaration, kept for the modules that need it
    #? before resolution. Modules should prefer `host` or `context`.
    inherit specs;
  };
}