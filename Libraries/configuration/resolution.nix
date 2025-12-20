{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;
  inherit (lib.debug) traceIf;
  inherit
    (builtins)
    parseDrvName
    getFlake
    unsafeDiscardStringContext
    ;
  flakeRef = (parseDrvName (unsafeDiscardStringContext (toString <nixpkgs>))).name;

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

  flake = path: let
    normalizedPath = flakePath path;
    loadResult = optionalAttrs (normalizedPath != null) (getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if loadResult == null
      then "getFlake returned null"
      else if (loadResult._type or null) != "flake"
      then "invalid flake type: ${(loadResult._type or "null")}"
      else "unknown";
    result =
      if (loadResult._type or null) == "flake"
      then loadResult // {srcPath = path;}
      else loadResult;
  in
    traceIf ((loadResult._type or null) != "flake")
    "❌ Flake load failed: ${toString path} (${failureReason})"
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
      flake
      flakePath
      flakeRef
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
    _rootAliases = {getFlake = flake;};
  }
