{
  lib ? import <nixpkgs/lib>,
  lix ? import ./libraries {inherit lib;},
  #? The raw host declaration, from `specs/`.
  specs ? import ./specs,
  #? The resolved host record. Derived from `specs` so a caller may pass either
  #? and get the same result; overridable to avoid resolving twice.
  host ? lix.schemas.host.mkHost specs,
  #? The resolved host argument bundle, from `context/`.
  context ? import ./context {inherit lix host;},
  #? The NixOS/Home Manager module tree.
  modules ? (import ./modules {inherit lix;}),
  ...
}: let
  #? The resolved host, plus the bundle the modules read from.
  #?
  #? `host` is the resolved host record. `infrastructure` is the resolution
  #? boundary over it: `data` (principals, packages, functionalities),
  #? `core` (host-level resolutions) and `home` (per-user selections).
  #?
  #? Modules read host *declarations* from `host` and *resolved* values from
  #? `infrastructure`, so the two stay distinct: `host.interface.desktops` is
  #? what the host declared, `infrastructure.core.packages.kernel` is the
  #? derivation that name resolved to.
  infrastructure = context;
in {
  imports = [modules];

  _module.args = {
    inherit lix host infrastructure;
    #? `specs` and `context` are kept as aliases so a module written against
    #? either name resolves; `host`/`infrastructure` are the canonical pair.
    inherit specs context;
  };
}