{
  src ? ./.,
  stems ? {},
  paths ? {},
  ...
} @ args: let
  resolveStem = {
    name,
    stem,
  }: let
    inherit (builtins) filter isList isString replaceStrings split;
    defined = stems.${name} or null;
    parsed =
      if isList defined
      then filter (part: isString part && part != "") defined
      else if isString defined
      then
        filter (part: isString part && part != "")
        (split "/" (replaceStrings ["."] ["/"] defined))
      else [];
  in
    if parsed != []
    then parsed
    else stem;

  resolvePath = {
    name,
    stem,
  }: let
    inherit (builtins) concatStringsSep isPath isString substring typeOf;
    resolvedStem = resolveStem {inherit name stem;};
    defined = paths.${name} or null;
  in
    if isPath defined
    then defined
    else if isString defined && defined != ""
    then
      if substring 0 1 defined == "/"
      then /. + defined
      else src + "/${defined}"
    else if defined != null
    then throw "paths.${name} must be a path or non-empty string, got ${typeOf defined}"
    else src + "/${concatStringsSep "/" resolvedStem}";
in
  import
  (resolvePath {
    name = "lib";
    stem = ["Libraries" "nix"];
  })
  (args // {mkLib = import ./.;})
