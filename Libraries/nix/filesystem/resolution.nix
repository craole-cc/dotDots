{
  _,
  src,
  lib,
  ...
}: let
  __doc = ''
    Filesystem Flake Resolution

    Provides utilities for locating, validating, and safely evaluating Nix flakes
    from the local filesystem. This acts as the foundational data-fetching layer
    for the repository, ensuring that flake paths are correctly normalized and
    evaluated before their inputs or modules are parsed.
  '';

  __exports = {
    internal = {
      inherit getFlakePath;
      getFlake = getFlake';
    };
    external = {
      inherit getFlakePath;
      inherit (__exports.internal) getFlake;
    };
  };

  inherit (builtins) getFlake;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.debug) traceIf;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;

  /**
  Resolves and validates the filesystem path to a flake directory.

  Checks if the provided path is either a directory containing a `flake.nix`
  or a direct path to a `flake.nix` file, normalizing it to the parent
  directory. If an already-evaluated flake (`self`) is provided, it
  bypasses path resolution and returns the flake's `outPath`.

  # Args:
    self: An evaluated flake to extract the `outPath` from directly.
    path: A filesystem path (string or path type) to check for a flake.

  # Returns:
    The normalized directory path as a string, or `null` if invalid.
  */
  getFlakePath = {
    self ? {},
    path ? src,
  }: let
    pathStr = toString path;
    fileStr = "/flake.nix";
    result =
      if hasSuffix fileStr pathStr && pathExists pathStr
      then dirOf pathStr
      else if pathExists (pathStr + fileStr)
      then pathStr
      else null;
  in
    if (self ? outPath)
    then self.outPath
    else
      traceIf (result == null)
      "❌ '${pathStr}' is not a valid flake path."
      result;

  /**
  Safely evaluates and retrieves a flake from a given path.

  Wraps `builtins.getFlake` with path normalization and detailed error
  tracing. If an already-evaluated flake (`self`) is provided, it returns
  it immediately without attempting to load the path.

  # Args:
    self: An already evaluated flake to return directly (bypasses evaluation).
    path: The filesystem path to the flake (defaults to the outer scope's `src`).

  # Returns:
    The evaluated flake attributes, including an appended `srcPath`.
  */
  getFlake' = {
    self ? {},
    path ? src,
  }: let
    normalizedPath = getFlakePath {inherit self path;};

    derived = optionalAttrs (normalizedPath != null) (
      getFlake normalizedPath
    );

    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if derived == null
      then "getFlake returned null"
      else if (derived._type or null) != "flake"
      then "invalid flake type: ${derived._type or "null"}"
      else "unknown";
  in
    if self != {}
    then self
    else
      traceIf
      ((derived._type or null) != "flake")
      "❌ Flake load failed: ${toString path} (${failureReason})"
      (derived // {srcPath = path;});
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
