{
  config,
  lib,
  options,
  ...
}: let
  inherit (lib.attrsets) foldlAttrs mapAttrs;
  inherit (lib.lists) concatLists foldl' last;
  inherit (lib.options) isOption;
  inherit (lib.types) anything;

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

  resolvedOptions = options._.resolved or {};

  optionDefaults = node:
    if isOption node
    then node.default or null
    else mapAttrs (_: optionDefaults) node;

  diff = defaults: values:
    if builtins.isAttrs values && builtins.isAttrs defaults
    then
      foldlAttrs (
        result: name: value:
          if defaults ? ${name}
          then
            let
              difference = diff defaults.${name} value;
            in
              if difference == {}
              then result
              else result // {${name} = difference;}
          else result // {${name} = value;}
      ) {} values
    else if values == defaults
    then {}
    else values;

  defaults = optionDefaults resolvedOptions;
in {
  options._ = {
    defaults = lib.mkOption {
      description = "Schema-derived default dotDots input values";
      default = {};
      type = anything;
    };
    updates = lib.mkOption {
      description = "Sparse dotDots input values differing from defaults";
      default = {};
      type = anything;
    };
    outputs = lib.mkOption {
      description = "Sparse effective NixOS configuration outputs";
      default = {};
      type = outputType;
    };
  };

  config._.defaults = defaults;
  config._.updates = diff defaults config._.resolved;
}
