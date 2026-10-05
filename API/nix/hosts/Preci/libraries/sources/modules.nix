{
  lix,
  inputs ? lix.inputs or null,
  sources,
  modules,
  ...
}: let
  inherit (lix.asserts) assertMsg;
  inherit (lix.attrsets) attrNames genAttrs mapAttrs;
  inherit (lix.fetchers) fetchModule;
  inherit (lix.strings) concatStringsSep isString;

  groups = ["core" "home"];

  # Registry entries say `source`; fetchModule expects `name`.
  #
  # `always` is a registry-local flag read by `context/modules.nix`, not an
  # argument `fetchModule` accepts, so it is stripped alongside `source`.
  # Passing it through is an `unexpected argument` error at resolution time --
  # which only surfaces for entries that set it, so the flag would work on
  # every host until the first `always = true` was added.
  resolve = group: module: spec: let
    ctx = concatStringsSep "." ["modules" group module];
    name = spec.source or null;
  in
    assert assertMsg (name != null)
    "${ctx}: missing required field 'source'";
    assert assertMsg (isString name && name != "")
    "${ctx}: field 'source' must be a non-empty string";
    assert assertMsg (sources ? name)
    "${ctx}: source '${name}' is not defined in registry.sources";
      fetchModule (
        {inherit inputs sources;}
        // (removeAttrs spec ["source" "always"])
        // {inherit name;}
      );

  resolved = genAttrs groups (
    group: mapAttrs (resolve group) modules.${group}
  );
in
  assert assertMsg (attrNames modules == groups)
  "modules: export list is out of sync with registry.modules"; ({inherit resolve;}
    // resolved
    // (with resolved; {
      nixosModules = core;
      homeModules = home;
    }))
