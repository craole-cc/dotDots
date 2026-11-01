{
  config,
  apps,
  top,
  lix,
  ...
}: let
  dom = "environment";
  mod = "applications";
  context = mkContext {inherit config dom mod;};

  inherit (context) cfg;
  inherit (lix.attrsets.access) foldlAttrs;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.content.emptiness) isNotEmpty;
  inherit (lix.lists.access) elemAt last;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.predicates) all;
  inherit (lix.lists.transformation) imap0;
  inherit (lix.modules.construction) mkConfig mkContext mkDefault;
  inherit (lix.options.construction) mkOption mkOptionType;
  inherit (lix.types.combinators) attrsOf listOf;
  inherit (lix.types.predicates) isAttrs isList;
  inherit (lix.types.primitives) anything str;

  variables = let
    roleSuffixes = ["PRI" "SEC" "TER"];
    mkVariables = fn:
      foldl' (
        acc: {
          name,
          key,
        }:
          acc // fn name cfg.selections.${key}
      ) {}
      [
        #? (exported name, selection key)
        {
          name = "TERMINAL";
          key = "terminal";
        }
        {
          name = "BROWSER";
          key = "browser";
        }
        {
          name = "EDITOR";
          key = "editor";
        }
        {
          name = "VISUAL";
          key = "ide";
        }
        {
          name = "EXPLORER";
          key = "explorer";
        }
        {
          name = "FILE_MANAGER";
          key = "explorer";
        }
      ];
  in
    (
      mkVariables (
        name: entries:
          optionalAttrs (entries != [])
          {${name} = (elemAt entries 0).command;}
      )
    )
    // (
      mkVariables (prefix: entries:
        foldl' (acc: entry: acc // entry) {} (
          imap0 (
            index: entry:
              optionalAttrs (isNotEmpty (entry.command or null)) (
                let
                  id = toString (index + 1);
                  base = {
                    "${prefix}_${id}" = entry.command;
                    "${prefix}_${id}_NAME" = entry.name;
                  };
                  role = optionalAttrs (index < 3) (let
                    suffix = elemAt roleSuffixes index;
                  in {
                    "${prefix}_${suffix}" = entry.command;
                    "${prefix}_${suffix}_NAME" = entry.name;
                  });
                in
                  base // role
              )
          )
          entries
        ))
    );

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
in
  (mkConfig {
    inherit context;
    predicate = true;
    options = {
      selections = mkOption {
        description = "Normalised application selections used to generate session variables";
        type = attrsOf (listOf (attrsOf anything));
        default = {inherit (apps) terminal browser editor ide explorer;};
      };
      variables = mkOption {
        description = ''
          Session variables derived from the selected applications

          Every selection receives an indexed variable. Named role suffixes remain
          aliases for the first three entries during migration (PRI/SEC/TER).

          This supports backward compatibility during a phased migration.
        '';
        default = variables;
        type = attrsOf str;
      };
    };

    outputs = {
      home.sessionVariables = mapAttrs (_name: mkDefault) cfg.variables;
    };
  })
  // {
    imports =
      [
        {
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
        }
      ]
      ++ (importAllPaths ./.).value;
  }
