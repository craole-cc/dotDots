{
  lib',
  strings,
}: let
  inherit (lib'.attrsets) attrNames listToAttrs;
  inherit (lib'.lists) filter head;
  inherit (strings) hasPrefix removePrefix removeSuffix toPascal;

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
    meta,
    functions,
  }: let
    #~@ ordered longest-first to avoid partial matches e.g. with vs without
    knownPrefixes = ["without" "with" "from" "has" "is" "mk" "to" "by"];

    extSuffix = toPascal (removeSuffix ".nix" meta.filename);
    namespace = "mk" + toPascal (toSingular meta.directory);

    stripFnPrefix = k: let
      matched = filter (p: hasPrefix p k) knownPrefixes;
    in
      if matched == []
      then k
      else removePrefix (head matched) k;

    mkAliases = fns:
      listToAttrs (map (k: {
        name = k + extSuffix;
        value = fns.${k};
      }) (attrNames fns));

    mkExternal = fns:
      listToAttrs (map (k: {
        name = namespace + toPascal (stripFnPrefix k) + extSuffix;
        value = fns.${k};
      }) (attrNames fns));
  in {
    internal = functions // mkAliases functions;
    external = mkExternal functions;
  };
in {
  inherit mkModuleExports toSingular;
}
