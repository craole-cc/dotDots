# Framework plumbing for the dotDots schema/outputs options.
# Lives beside default.nix so importAllPaths picks it up; move it to your
# root module if you prefer.
{
  top,
  lix,
  ...
}: let
  inherit (lix.attrsets.transformation) zipAttrsWith;
  inherit (lix.lists.aggregation) all last;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.predicates) isAttrs isList;
  inherit (lix.types.primitives) anything;

  # Attrsets merge recursively, lists concatenate, anything else: last wins.
  # NOTE: "last" depends on definition order, and mkDefault/mkOverride wrappers
  # are merged as plain attrsets here, so their priorities are not honoured.
  mergeOutput = values:
    if all isAttrs values
    then zipAttrsWith (_name: mergeOutput) values
    else if all isList values
    then concatLists values
    else last values;
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
      description = ''
        Sparse effective Home Manager configuration outputs

        Attrsets merge recursively, lists concatenate, and conflicting scalars
        resolve to the last definition.
      '';
      default = {};
      type = mkOptionType {
        name = "home output";
        description = "recursively merged Home Manager output";
        check = _: true;
        merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
      };
    };
  };
}
