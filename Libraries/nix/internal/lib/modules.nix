{lib, ...}: let
  __exports =
    {
      inherit
        evaluation
        merging
        migration
        utils
        ;
    }
    // evaluation
    // merging
    // migration
    // utils
    // {};

  merging = {
    inherit
      (lib.modules)
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
      ;
  };

  migration = {
    inherit
      (lib.modules)
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

  evaluation = {
    inherit
      (lib.modules)
      evalModules
      evalOptionValue
      ;
  };

  utils = {
    inherit
      (lib.modules)
      fixMergeModules
      importApply
      importJSON
      importTOML
      mkDerivedConfig
      setDefaultModuleLocation
      ;
  };
in
  __exports
