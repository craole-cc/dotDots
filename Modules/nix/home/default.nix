{lib, lix, ...}: {
  options._.output = lib.mkOption {
    description = "Staged Home Manager config output intended for writing";
    default = {};
    # Keep this an untyped staging surface: module-system definitions may
    # contain attrsets, lists, derivations, or other declared Nix values.
    type = lib.types.unspecified;
  };

  imports = lix.filesystem.importers.importAll ./.;
}
