{
  lix,
  inputs ? lix.inputs or null,
  sources,
  modules,
  ...
}: let
  inherit (lix.asserts) assertMsg;
  inherit (lix.attrsets) mapAttrs recursiveUpdate;
  inherit (lix.fetchers) fetchModule;

  resolveModule = arguments: fetchModule (arguments // {inherit inputs sources;});

  # Registry entries say `source`; fetchModule expects `name`.
  #
  # `always` is a registry-local flag read by `context/modules.nix`, not an
  # argument `fetchModule` accepts, so it is stripped alongside `source`.
  # Passing it through is an `unexpected argument` error at resolution time --
  # which only surfaces for entries that set it, so the flag would work on
  # every host until the first `always = true` was added.
  resolveSpec = group: moduleName: spec:
    assert assertMsg (sources ? ${spec.source})
    "modules.${group}.${moduleName}: source '${spec.source}' is not defined in registry.sources";
      resolveModule (
        (removeAttrs spec ["source" "always"]) // {name = spec.source;}
      );
in {
  inherit resolveModule;

  mkNixPkgs = {
    system,
    overlays ? [],
    allowUnfree ? config.allowUnfree or true,
    allowBroken ? config.allowBroken or false,
    config ? {},
  }:
    import sources.nixpkgs.path {
      inherit system overlays;
      config = recursiveUpdate config {
        inherit allowUnfree allowBroken;
      };
    };

  core = mapAttrs (resolveSpec "core") modules.core;
  home = mapAttrs (resolveSpec "home") modules.home;
}
