{
  config,
  lix,
  options,
  top,
  ...
}: let
  inherit (lix.attrsets.access) foldlAttrs;
  inherit (lix.attrsets.transformation) mapAttrs removeAttrs;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.access) last;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) all;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.primitives) anything;
  inherit (lix.types.predicates) isAttrs isList isOption;

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
                  then mergeOutput [result.${name} item]
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
    name = "staged output";
    description = "recursively merged staged output";
    check = _: true;
    merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
  };

  resolvedOptions = options.${top}.resolved or {};

  optionDefaults = node:
    if isOption node
    then node.default or null
    else mapAttrs (_: optionDefaults) node;

  diff = defaults: values:
    if isAttrs values && isAttrs defaults
    then
      foldlAttrs (
        result: name: value:
          if defaults ? ${name}
          then let
            difference = diff defaults.${name} value;
          in
            if difference == {}
            then result
            else result // {${name} = difference;}
          else result // {${name} = value;}
      ) {}
      values
    else if values == defaults
    then {}
    else values;

  defaults = optionDefaults resolvedOptions;
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
      description = "Sparse effective NixOS configuration outputs";
      default = {};
      type = outputType;
    };
  };

  config.${top} = {
    inherit defaults;
    updates = diff defaults config.${top}.resolved;
    outputs = {
      home-manager.users = mapAttrs (_: user: removeAttrs user [top]) config.home-manager.users;
    };
  };
}
