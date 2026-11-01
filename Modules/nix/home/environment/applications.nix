{
  config,
  apps,
  lix,
  ...
}: let
  dom = "environment";
  mod = "applications";
  context = mkContext {inherit config dom mod;};

  inherit (context) cfg;
  inherit (lix.attrsets.aggregation) mergeAttrsList;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) concatMapAttrs mapAttrs;
  inherit (lix.content.emptiness) isNotEmpty;
  inherit (lix.lists.access) elemAt head length;
  inherit (lix.lists.construction) concatLists optional;
  inherit (lix.lists.transformation) filter imap0;
  inherit (lix.modules.construction) mkConfig mkContext mkDefault;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) attrsOf listOf nullOr submodule;
  inherit (lix.types.primitives) anything str;

  #? exported variable name -> selection key
  selectionKeys = {
    TERMINAL = "terminal";
    BROWSER = "browser";
    EDITOR = "editor";
    VISUAL = "ide";
    EXPLORER = "explorer";
  };

  # TODO(remove): drop the PRI/SEC/TER aliases once no consumer reads them.
  roleSuffixes = ["PRI" "SEC" "TER"];

  # Entries without a command are dropped *before* numbering, so indices
  # (and therefore _1/_PRI etc.) never have gaps.
  mkSelectionVariables = prefix: entries: let
    usable = filter (entry: isNotEmpty entry.command) entries;

    mkEntryVariables = index: entry: let
      suffixes =
        [(toString (index + 1))]
        ++ optional (index < length roleSuffixes) (elemAt roleSuffixes index);
    in
      map (suffix: {
        "${prefix}_${suffix}" = entry.command;
        "${prefix}_${suffix}_NAME" = entry.name;
      })
      suffixes;
  in
    optionalAttrs (usable != []) {${prefix} = (head usable).command;}
    // mergeAttrsList (concatLists (imap0 mkEntryVariables usable));

  variables =
    concatMapAttrs
    (prefix: key: mkSelectionVariables prefix cfg.selections.${key})
    selectionKeys;

  entryType = submodule {
    freeformType = attrsOf anything;
    options = {
      name = mkOption {
        description = "Display name of the application";
        type = str;
      };
      command = mkOption {
        description = "Command used to launch the application";
        type = nullOr str;
        default = null;
      };
    };
  };
in
  mkConfig {
    inherit context;
    predicate = true;
    options = {
      selections = mkOption {
        description = "Application selections used to generate session variables";
        type = attrsOf (listOf entryType);
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
        readOnly = true;
        internal = true;
      };
    };

    outputs = {
      home.sessionVariables = mapAttrs (_name: mkDefault) cfg.variables;
    };
  }
