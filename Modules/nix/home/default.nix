{
  top,
  lix,
  options,
  config,
  ...
}: let
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.predicates) isDerivation;
  inherit (lix.attrsets.transformation) concatMapAttrs filterAttrs mapAttrs;
  inherit (lix.modules.construction) mkLayer;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.primitives) anything;
  inherit (lix.types.predicates) isAttrs;
  inherit (lix.filesystem.traversal) importAllPaths;

  declaredDefaults = declarations:
    if declarations ? explicit
    then declaredDefaults declarations.explicit
    else
      mapAttrs
      (_name: declaration:
        if (declaration._type or null) == "option"
        then declaration.default
        else declaredDefaults declaration)
      (filterAttrs
        (name: declaration:
          name
          != "implicit"
          && ((declaration._type or null) != "option" || declaration ? default))
        declarations);

  resolvedInputs = declarations: values:
    if declarations ? explicit
    then values.explicit
    else
      mapAttrs
      (name: declaration:
        if (declaration._type or null) == "option"
        then values.${name}
        else resolvedInputs declaration values.${name})
      (filterAttrs (name: _declaration: name != "implicit") declarations);

  isPlainAttrs = value: isAttrs value && !(value ? _type) && !(isDerivation value);

  differingInputs = defaults: values:
    concatMapAttrs
    (name: value:
      if !(defaults ? ${name})
      then {${name} = value;}
      else if isPlainAttrs value && isPlainAttrs defaults.${name} && value != {}
      then let
        changes = differingInputs defaults.${name} value;
      in
        optionalAttrs (changes != {}) {${name} = changes;}
      else optionalAttrs (value != defaults.${name}) {${name} = value;})
    values;
in {
  imports = (importAllPaths ./.).value;
  config.${top} = {
    defaults = mkLayer 1000 (declaredDefaults (options.${top}.resolved or {}));
    updates = differingInputs config.${top}.defaults (
      resolvedInputs (options.${top}.resolved or {}) (config.${top}.resolved or {})
    );
  };
  options.${top} = {
    defaults = mkOption {
      description = "Declared dotDots input defaults without explicit or implicit wrappers, with local baselines taking precedence";
      default = {};
      type = anything;
    };

    updates = mkOption {
      description = "Sparse resolved dotDots input overrides, using the same paths as defaults";
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
