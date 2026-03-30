{lib, ...}: let
  __exports =
    {
      inherit
        declaration
        introspection
        ;
    }
    // declaration
    // introspection
    // {};

  declaration = {
    inherit
      (lib.options)
      mergeUniqueOption
      mkEnableOption
      mkOption
      mkPackageOption
      mkSinkUndeclaredOptions
      ;
  };

  introspection = {
    inherit
      (lib.options)
      isOption
      showFiles
      showOption
      ;

    inherit
      (lib.types)
      isOptionType
      ;
  };
in
  __exports
