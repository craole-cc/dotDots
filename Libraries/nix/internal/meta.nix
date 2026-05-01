{lib}: let
  inherit (lib.attrsets) attrNames listToAttrs optionalAttrs;
  inherit (lib.lists) filter head map uniqueStrings;
  inherit
    (lib.strings)
    concatStrings
    hasPrefix
    optionalString
    removePrefix
    removeSuffix
    splitString
    stringLength
    substring
    toLower
    toUpper
    ;

  capitalize = input:
    optionalString
    (input != "" && input != null)
    (
      ""
      + toUpper (substring 0 1 input)
      + substring 1 (stringLength input - 1) input
    );

  uncapitalize = input:
    optionalString
    (input != "" && input != null)
    (
      ""
      + toLower (substring 0 1 input)
      + substring 1 (stringLength input - 1) input
    );

  toPascal = input:
    concatStrings (
      map capitalize (splitString "-" input)
    );

  toSingular = let
    #~@ irregular plurals that can't be handled by stripping trailing s
    irregulars = {};
  in
    word: irregulars.${word} or (removeSuffix "s" word);

  mkModuleExports = {
    directory,
    functions,
    filename ? null,
    doc ? null,
    tests ? null,
    prefixes ? [],
  }: let
    domain = toPascal (toSingular directory);
    suffix =
      optionalString
      (filename != null && filename != "")
      (toPascal filename);

    splitFnPrefix = stem: let
      commonPrefixes = [
        "without"
        "with"
        "from"
        "has"
        "is"
        "mk"
        "to"
        "by"
        "on"
      ];
      prefixes' =
        filter
        (prefix: hasPrefix prefix stem)
        (uniqueStrings (prefixes ++ commonPrefixes));
      isPrefixed = prefixes' != [];
      prefix = optionalString isPrefixed (head prefixes');
    in {
      inherit prefix;
      stem =
        if isPrefixed
        then removePrefix prefix stem
        else stem;
    };

    mkAliases = fns:
      optionalAttrs
      (suffix != "")
      (
        listToAttrs (map (fn: {
          name = fn + suffix;
          value = fns.${fn};
        }) (attrNames fns))
      );

    mkExternalName = fn: let
      inherit suffix domain;
      inherit (splitFnPrefix fn) prefix stem;
      name = toPascal stem;
    in
      uncapitalize (prefix + domain + name + suffix);

    mkExternal = fns:
      listToAttrs (
        map (fn: {
          name = mkExternalName fn;
          value = fns.${fn};
        }) (attrNames fns)
      );
  in
    functions
    // mkAliases functions
    # // optionalAttrs (doc != null || doc != "") {_docs = doc;}
    # // optionalAttrs (tests != {} || tests != null) {__tests = tests;}
    optionalAttrs (doc != null || doc != "") {_docs = doc;}
    optionalAttrs (tests != {} || tests != null) {__tests = tests;}
    {__rootAliases = mkExternal functions;};
in {
  inherit mkModuleExports toSingular;
}
