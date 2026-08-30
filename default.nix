{
  src ? ./.,
  stems ? {},
  paths ? {},
  ...
} @ args: let
  resolvePathStem = {
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
    resolvedStem = resolvePathStem {inherit name stem;};
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

  importModules = input: let
    inherit (builtins) attrNames filter readDir pathExists listToAttrs isFunction isPath isString;

    isDirectPath = isPath input || isString input;
    path =
      if isDirectPath
      then input
      else input.path;
    args =
      if isDirectPath
      then {}
      else (input.args or {});

    callImport = target: let
      exec = import target;
    in
      if isFunction exec
      then exec args
      else exec;
  in
    if !pathExists (path + "/.")
    then callImport path
    else let
      data = readDir path;

      isLoadable = name:
        name
        != "nix"
        && data.${name} == "directory"
        && pathExists (path + "/${name}/default.nix");

      base =
        if pathExists (path + "/nix/default.nix")
        then callImport (path + "/nix")
        else {};

      others = listToAttrs (map (name: {
        inherit name;
        value = callImport (path + "/${name}");
      }) (filter isLoadable (attrNames data)));
    in
      base // others;

  modules = importModules {
    inherit args;
    path = src;
  };

  sourceLib = import ./.;
in
  import
  (resolvePath {
    name = "lib";
    stem = ["Libraries" "nix"];
  })
  (args // {inherit importModules sourceLib modules;})
