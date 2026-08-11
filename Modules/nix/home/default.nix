{
  _,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) foldlAttrs;
  inherit (lib.lists) concatLists foldl' last;

  mergeOutput = values:
    if builtins.all builtins.isAttrs values
    then
      foldl' (
        merged: value:
          foldlAttrs (
            result: name: item:
              result
              // {
                ${name} =
                  if result ? ${name}
                  then mergeOutput [result.${name} item]
                  else item;
              }
          ) merged value
      ) {} values
    else if builtins.all builtins.isList values
    then concatLists values
    else last values;

  outputType = lib.types.mkOptionType {
    name = "staged output";
    description = "recursively merged staged output";
    check = _: true;
    merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
  };
in {
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
      type = outputType;
    };
  };

  imports = lix.filesystem.importers.importAll ./.;
}
