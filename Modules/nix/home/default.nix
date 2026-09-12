{
  top,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) foldlAttrs;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.access) last;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) all;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.primitives) anything;
  inherit (lix.types.predicates) isAttrs isList;

  mergeOutput = values:
    if all isAttrs values
    then
      foldl' (
        merged: value:
          foldlAttrs (
            result: name: item:
              result
              // {
                ${name} =
                  if result ? ${name}
                  then
                    mergeOutput [
                      result.${name}
                      item
                    ]
                  else item;
              }
          )
          merged
          value
      ) {}
      values
    else if all isList values
    then concatLists values
    else last values;

  outputType = mkOptionType {
    name = "home output";
    description = "recursively merged Home Manager output";
    check = _: true;
    merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
  };
in {
  options.${top} = {
    defaults = mkOption {
      description = "Schema-derived default dotDots input values";
      default = {};
      type = anything;
    };
    updates = mkOption {
      description = "Sparse dotDots input values differing from defaults";
      default = {};
      type = anything;
    };
    outputs = mkOption {
      description = "Sparse effective Home Manager configuration outputs";
      default = {};
      type = outputType;
    };
  };

  # Home is being migrated incrementally to the same mkContext/mkConfig
  # contract as Core. Only migrated modules are wired here; the legacy tree
  # remains available for staged conversion without participating in eval.
  imports = [
    ./applications
    ./interface/options.nix
    ./interface/catppuccin.nix
    ./interface/dms.nix
    ./interface/manager/hyprland
  ];
}
