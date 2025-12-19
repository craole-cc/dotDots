{
  _,
  lib,
  ...
}: let
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;
  # inherit (lib.debug) traceIf;
  inherit (builtins) readFile storePath tryEval fromJSON;

  readRegistry = registryPath:
    if pathExists registryPath
    then let
      content = readFile registryPath;
      parsed = tryEval (fromJSON content);
    in
      with parsed;
        if success
        then value
        else {
          flakes = [];
          version = 0;
        }
    else {
      flakes = [];
      version = 0;
    };

  flakePath = path: let
    pathStr = toString path;
    result =
      if hasSuffix "/flake.nix" pathStr && pathExists pathStr
      then dirOf pathStr
      else if pathExists (pathStr + "/flake.nix")
      then pathStr
      else null;
  in
    result;

  flakeAuto = {
    flake = import <nixpkgs> {};
    url = "path:" + toString (import <nixpkgs> {});
    path = storePath (import <nixpkgs> {});
  };

  flakePathFromRegistry = registryPath: let
    registry = readRegistry registryPath;
    result = "";
  in
    result;

  # loadFlake = path: let
  #   # flakePath = normalizeFlake path;
  #   flakePathFromReg =
  # in
  #   # traceIf (flakePath != null)
  #   # "Flake found: ${flakePath}"
  #   # (builtins.getFlake flakePath);

  exports = {
    inherit
      flakePath
      flakePathFromRegistry
      flakeAuto
      # normalizeFlake
      # loadFlake
      ;
  };
in
  exports
  // {
    __doc = ''
      Flake stuff
    '';
    _rootAliases = {
    };
  }
