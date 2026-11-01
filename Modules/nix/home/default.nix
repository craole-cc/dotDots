{
  top,
  lix,
  ...
}: let
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.primitives) anything;
  inherit (lix.filesystem.traversal) importAllPaths;
in {
  imports = (importAllPaths ./.).value;
  options.${top} = {
    defaults = mkOption {
      description = "Schema-derived default dotDots input values";
      # TODO: I would a complete constructed set of defaults for every declaration. maybe it's best to define locally. So for instance in Modules/nix/home/terminal/core/ghostty/default.nix (just a random one), we should be producing defaults (user-agnostic) alongside the resolutions and outputs
      default = {};
      type = anything;
    };

    updates = mkOption {
      description = "Sparse dotDots input values differing from defaults";
      default = {};
      type = anything;
    };

    outputs = mkOption {
      description = ''
        Sparse effective Home Manager configuration outputs

        Plain attrsets merge recursively; conflicting lists, scalars, and tagged
        module values resolve to the last definition. An empty plain attrset
        preserves an earlier tagged module value.
      '';
      default = {};
      type = mkOptionType {
        name = "home output";
        description = "recursively merged Home Manager output";
        check = _: true;
        merge = _: definitions: mergeSafe (map (definition: definition.value) definitions);
      };
    };
  };
}
