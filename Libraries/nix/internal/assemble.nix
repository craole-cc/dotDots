{
  lib',
  customLib,
  path,
}: let
  lib = {
    modules = with lib'.modules; {
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

    options = lib'.options or {};

    types = removeAttrs (lib'.types or {}) ["types"];
  };

  lix = customLib.extend (_: prev: {
    inherit path;
    src = path;
    lib = lib';

    modules =
      prev.modules or {}
      // lib.modules
      // prev.types.modules or {};

    # options =
    #   lib.options
    #   // prev.types.options or {};

    types =
      prev.types or {}
      // lib.types
      // lib.options
      // prev.types.options or {}
      // prev.types.predicates or {};
  });
in
  removeAttrs lix ["__unfix__" "unfix" "extend"]
  // {extend = f: lix.extend f;}
