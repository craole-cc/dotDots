{lix, ...}: let
  inherit (lix.enums.hardware) gpuBrands;
  inherit (lix.std.attrsets) attrValues;
  inherit (lix.std.lists) any optional;
  inherit (lix.std.options) mkOption mkEnableOption mkDefault;
  inherit (lix.std.types) attrsOf enum nullOr str submodule;

  gpuOpts = {
    name,
    config,
    ...
  }: {
    options = {
      primary = mkEnableOption "Set as primary GPU for display and rendering";
      secondary = mkEnableOption "Set as secondary GPU for offload/hybrid use";
      brand = mkOption {
        description = "GPU brand/vendor for driver selection and hardware acceleration";
        type = enum gpuBrands.enum;
      };
      busId = mkOption {
        description = "PCI bus ID in format 'PCI:X:Y:Z'";
        default = null;
        example = "PCI:6:0:0";
        type = nullOr str;
      };
      model = mkOption {
        default = "";
        type = str;
      };
    };

    config = {
      #? Exactly one GPU must be primary
      primary = mkDefault (any (cfg: cfg.primary) (attrValues config));

      #? Warn if no primary GPU defined
      _warnings = optional (!config.primary or false) ''
        No primary GPU defined in ${config._module.args.name or "gpu"}.
        Set primary = true on exactly one GPU entry.
      '';
    };
  };
in {
  gpu = mkOption {
    description = ''
      GPU configuration for single or hybrid setups.

      Keys are GPU identifiers (nvidia, amd, intel, etc.).
      Exactly one GPU across all entries must have primary = true.

      Get busId: lspci | grep -E "VGA|3D" | cut -d' ' -f1
    '';
    default = {};
    example = {};
    type = attrsOf (submodule gpuOpts);
  };
}
