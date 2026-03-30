{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        construction
        evaluation
        migration
        ;
    };
    flattened =
      {}
      // construction
      // evaluation
      // migration
      // {};
  };

  inherit (lib) modules;

  construction = {
    inherit
      (modules)
      mkAfter
      mkAssert
      mkBefore
      mkDefault
      mkDefinition
      mkForce
      mkIf
      mkImageMediaOverride
      mkMerge
      mkOptionDefault
      mkOrder
      mkOverride
      mkVMOverride
      fixMergeModules
      mkDerivedConfig
      setDefaultModuleLocation
      ;
  };

  evaluation = {
    inherit
      (modules)
      evalModules
      evalOptionValue
      importApply
      importJSON
      importTOML
      ;
  };

  migration = {
    inherit
      (modules)
      doRename
      mkAliasAndWrapDefsWithPriority
      mkAliasAndWrapDefinitions
      mkAliasDefinitions
      mkAliasIfDef
      mkAliasOptionModule
      mkChangedOptionModule
      mkMergedOptionModule
      mkRemovedOptionModule
      mkRenamedOptionModule
      mkRenamedOptionModuleWith
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
