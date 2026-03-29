{lib, ...}: {
  modules = with lib.modules; {
    inherit
      #~@ Conditional / merge helpers
      mkIf
      mkMerge
      mkAfter
      mkBefore
      mkOrder
      mkForce
      mkDefault
      mkOverride
      mkOptionDefault
      mkVMOverride
      mkImageMediaOverride
      mkDefinition
      mkAssert
      #~@ Option declaration
      mkOption
      mkEnableOption
      mkPackageOption
      mkSinkUndeclaredOptions
      #~@ Option renaming / migration
      mkAliasOptionModule
      mkRenamedOptionModule
      mkRenamedOptionModuleWith
      mkRemovedOptionModule
      mkChangedOptionModule
      mkMergedOptionModule
      mkAliasIfDef
      mkAliasDefinitions
      mkAliasAndWrapDefinitions
      mkAliasAndWrapDefsWithPriority
      #~@ Evaluation
      evalModules
      evalOptionValue
      #~@ Misc
      mkDerivedConfig
      doRename
      setDefaultModuleLocation
      fixMergeModules
      importApply
      importJSON
      importTOML
      ;
  };
}
