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

  flakeAttr = path: let
    normalizedPath = flakePath path;
    loadResult = optionalAttrs (normalizedPath == null) getFlake normalizedPath;
  in
    traceIf
    (loadResult == {})
    "❌ Flake load failed: ${toString path}"
    loadResult;

  # loadFlake = path: let
  #   # flakePath = normalizeFlake path;
  #   flakePathFromReg =
  # in
  #   # traceIf (flakePath != null)
  #   # "Flake found: ${flakePath}"
  #   # (builtins.getFlake flakePath);

  exports = {
    inherit
      flakeAttr
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
    _rootAliases = exports;
  }
