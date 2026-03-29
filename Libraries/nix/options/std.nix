{lib, ...}: {
  inherit
    (lib.options)
    mergeUniqueOption
    mkEnableOption
    mkOption
    mkPackageOption
    mkSinkUndeclaredOptions
    ;

  inherit
    (lib.modules)
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

  inherit
    (lib.types)
    mkOptionType
    str
    bool
    int
    float
    path
    ;
}
