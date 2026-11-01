# TODO: Should this file use mkConfig/mkContract??
{
  top,
  apps,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) foldlAttrs;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.access) elemAt last;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.predicates) all;
  inherit (lix.lists.transformation) imap0;
  inherit (lix.modules.construction) mkDefault;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.predicates) isAttrs isList;
  inherit (lix.types.primitives) anything;

  mkSelectionVariables = prefix: entries:
    foldl' (variables: entry: variables // entry) {} (imap0 (index: entry:
      optionalAttrs ((entry.command or null) != null) (
        {
          "${prefix}_${toString (index + 1)}" = mkDefault entry.command;
          "${prefix}_${toString (index + 1)}_NAME" = mkDefault entry.name;
        }
        // optionalAttrs (index < 3) (let
          suffix = elemAt ["PRI" "SEC" "TER"] index;
        in {
          "${prefix}_${suffix}" = mkDefault entry.command;
          "${prefix}_${suffix}_NAME" = mkDefault entry.name;
        })
      ))
    entries);

  mkDefaultVariable = name: entries:
    optionalAttrs (entries != []) {${name} = mkDefault (elemAt entries 0).command;};

  primaryVariables = let
    mk = var: val: mkDefaultVariable var apps.${val};
  in
    mk "TERMINAL" "terminal"
    // mk "BROWSER" "browser"
    // mk "EDITOR" "editor"
    // mk "VISUAL" "ide"
    // mk "EXPLORER" "explorer"
    // mk "FILE_MANAGER" "explorer";

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
      type = mkOptionType {
        name = "home output";
        description = "recursively merged Home Manager output";
        check = _: true;
        merge = _: definitions: mergeOutput (map (definition: definition.value) definitions);
      };
    };
  };

  #? Every selection receives an indexed variable. Named role suffixes remain
  #? aliases for the first three entries during migration (PRI/SEC/TER).
  #? This supports backward compatibility during a phased migration.
  config.home = {
    sessionVariables = let
      mk = var: val: mkSelectionVariables var apps.${val};
    in
      primaryVariables
      // (mk "TERMINAL" "terminal")
      // (mk "BROWSER" "browser")
      // (mk "EDITOR" "editor")
      // (mk "VISUAL" "ide")
      // (mk "EXPLORER" "explorer")
      // (mk "FILE_MANAGER" "explorer");
  };

  imports = (importAllPaths ./.).value;
}
