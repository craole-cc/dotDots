{
  lix,
  inputs,
  sources,
  overlays,
  modules,
  ...
}: let
  inherit (lix.asserts) assertMsg;
  inherit (lix.attrsets) mapAttrs;
  inherit (lix.fetchers) fetchModule;
  inherit (lix.lists) elem optional optionals;
  inherit (lix.trivial) isNotEmpty;

  resolveModule = arguments: fetchModule (arguments // {inherit inputs sources;});

  # Registry entries say `source`; fetchModule expects `name`.
  resolveSpec = group: moduleName: spec:
    assert assertMsg (sources ? ${spec.source})
    "modules.${group}.${moduleName}: source '${spec.source}' is not defined in registry.sources";
      resolveModule ((removeAttrs spec ["source"]) // {name = spec.source;});
in {
  inherit resolveModule;

  mkNixPkgs = {
    host ? {},
    system ?
      host.args.system or (
        throw "mkNixPkgs: 'system' or 'host.args.system' must be provided."
      ),
    extraOverlays ? [],
    config ? ((host.args.config or {}).nixpkgs or {allowUnfree = true;}),
  }:
    import sources.nixpkgs.path {
      inherit system config;
      overlays =
        optionals (isNotEmpty extraOverlays) extraOverlays
        ++ optional
        (elem "rust" (host.args.functionalities or []))
        overlays.rust-overlay;
    };

  core = mapAttrs (resolveSpec "core") modules.core;
  home = mapAttrs (resolveSpec "home") modules.home;
}
