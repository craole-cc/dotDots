/**
libraries/packages/resolve.nix

Pure package and binary resolution helpers for lib.packages.
*/
{lib}: let
  inherit (lib.attrsets) attrNames mapAttrs filterAttrs;
  inherit (lib.trivial) isNotEmpty;

  /**
  Resolve a derivation's main executable path.

  # Inputs
  - `drv`: A derivation package with an executable output.

  # Type
  ```nix
  resolveBin :: derivation -> string
  ```

  # Examples
  ```nix
  resolveBin pkgs.hello
  # => "/nix/store/.../bin/hello"
  ```

  # Returns
  The absolute path to the derivation's main executable.
  */
  resolveBin = drv:
    if lib ? getExe
    then lib.getExe drv
    else "${drv}/bin/${drv.meta.mainProgram or drv.pname or (lib.parseDrvName drv.name).name}";

  resolveBins = packages:
    mapAttrs
    (_: resolveBin)
    (filterAttrs (_: isNotEmpty) packages);

  /**
  Convert an attrset of derivations into an attrset of executable paths.

  Null values are dropped first.

  # Type
  ```nix
  mkBins :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkBins {
    hello = pkgs.hello;
    skipped = null;
  }
  # => {
  #   hello = "/nix/store/.../bin/hello";
  # }
  ```

  # Returns
  An attrset of executable paths with `null` package entries removed first.
  */
  mkBins = packages:
    mapAttrs (_: resolveBin)
    (removeAttrs packages (
      attrNames (filterAttrs (_: v: v == null) packages)
    ));

  /**
  Map executable paths into shell-command helpers.

  # Type
  ```nix
  mkCmds :: AttrSet -> (string -> string) -> AttrSet
  ```

  # Examples
  ```nix
  mkCmds { hello = "/nix/store/.../bin/hello"; } (bin: "${bin} --help")
  # => {
  #   hello = "/nix/store/.../bin/hello --help";
  # }
  ```

  # Returns
  An attrset produced by mapping each binary path through the provided function.
  */
  # Logic: Map over bins, apply f, and filter out any null results automatically.
  mkCmds = bins: f:
    filterAttrs (_: isNotEmpty) (mapAttrs (
        _: bin:
          if isNotEmpty bin
          then f bin
          else null
      )
      bins);
in {
  inherit
    resolveBin
    resolveBins
    mkBins
    mkCmds
    ;
}
