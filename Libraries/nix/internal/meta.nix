{lib'}: let
  inherit (lib'.attrsets) attrNames listToAttrs optionalAttrs;
  inherit (lib'.lists) filter head;
  inherit (lib'.strings) hasPrefix removePrefix removeSuffix concatStrings splitString toUpper substring stringLength;

  #> minimal toPascal using only nixpkgs — custom _.strings.transformation.toPascal not available here
  capitalize = s:
    if s == ""
    then ""
    else toUpper (substring 0 1 s) + substring 1 (stringLength s - 1) s;

  toPascal = s:
    concatStrings (map capitalize (splitString "-" s));

  toSingular = let
    #~@ irregular plurals that can't be handled by stripping trailing s
    irregulars = {
      # add as needed
    };
  in
    word:
      if irregulars ? ${word}
      then irregulars.${word}
      else removeSuffix "s" word;

  mkModuleExports = {
    directory,
    filename ? "",
    functions,
    doc ? "",
    tests ? {},
  }: let
    knownPrefixes = [
      "by"
      "from"
      "has"
      "is"
      "mk"
      "on"
      "to"
      "with"
      "without"
    ];

    extSuffix =
      if filename == ""
      then ""
      else toPascal filename;
    domain = toPascal (toSingular directory);

    splitFnPrefix = k: let
      matched = filter (p: hasPrefix p k) knownPrefixes;
    in
      if matched == []
      then {
        prefix = "";
        stem = k;
      }
      else let
        p = head matched;
      in {
        prefix = p;
        stem = removePrefix p k;
      };

    mkAliases = fns:
      optionalAttrs (extSuffix != "")
      (listToAttrs (map (k: {
        name = k + extSuffix;
        value = fns.${k};
      }) (attrNames fns)));

    mkExternal = fns:
      listToAttrs (map (k: {
        name = let
          parts = splitFnPrefix k;
        in
          parts.prefix + domain + parts.stem + extSuffix;
        value = fns.${k};
      }) (attrNames fns));
  in
    (functions // mkAliases functions)
    // {
      __rootAliases = mkExternal functions;
      __doc = doc;
    }
    // optionalAttrs (tests != {}) {__tests = tests;};
in {inherit mkModuleExports toSingular;}
