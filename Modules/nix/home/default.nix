{lib, lix, ...}: {
  options._ = {
    defaults = lib.mkOption {
      description = "Schema-derived default dotDots input values";
      default = {};
      type = lib.types.anything;
    };
    updates = lib.mkOption {
      description = "Sparse dotDots input values differing from defaults";
      default = {};
      type = lib.types.anything;
    };
    outputs = lib.mkOption {
      description = "Sparse effective Home Manager configuration outputs";
      default = {};
      type = lib.types.anything;
    };
  };

  imports = lix.filesystem.importers.importAll ./.;
}
