/**
libraries/packages/resolve.nix

Pure package and binary resolution helpers for lib.packages.
*/
{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    isAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    ;
  inherit (lib.trivial) isNotEmpty;
  inherit
    (lib.strings)
    concatStringsSep
    parseDrvName
    escapeShellArg
    isString
    optionalString
    ;

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
  resolveBin = input: let
    resolve = {
      drv,
      name ? null,
      program ? null,
    }: let
      parsed =
        if drv ? name
        then parseDrvName drv.name
        else {
          name = null;
          version = null;
        };

      mainProgram =
        if program != null
        then program
        else if drv ? meta.mainProgram
        then drv.meta.mainProgram
        else
          drv.NIX_MAIN_PROGRAM or (drv.pname or (
            if name != null
            then name
            else parsed.name
          ));
    in
      if mainProgram == null
      then throw "resolveBin: could not determine main program for derivation"
      else "${drv}/bin/${mainProgram}";
  in
    if isAttrs input && input ? drv
    then resolve input
    else if isString input
    then
      drv:
        resolve {
          name = input;
          inherit drv;
        }
    else
      resolve {
        drv = input;
      };

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
  # => { hello = "/nix/store/.../bin/hello"; }
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

  mkVr3n = bin: {
    field ? 2,
    head ? false,
    strip ? false,
    custom ? null,
  }: let
    base = "${bin} --version 2>&1";
    piped =
      if head
      then "${base} | head -n1"
      else base;
    dollar = "$";
    awk =
      if strip
      then "awk '{print substr(${dollar}${toString field},2)}'"
      else "awk '{print ${dollar}${toString field}}'";
  in
    if custom != null
    then custom
    else "${piped} | ${awk}";

  mkAlias = {
    pkgs,
    name,
    command,
    prefix ? null,
    sep ? null,
  }: let
    var =
      if (prefix != null)
      then
        concatStringsSep (
          if sep != null
          then sep
          else "_"
        ) [prefix name]
      else name;
    val =
      pkgs.writeShellScriptBin var ''exec ${command} "$@"'';
  in
    nameValuePair var val;

  mkBin = {
    pkgs,
    set,
    prefix ? null,
    sep ? null,
    exclude ? [],
  }:
    mapAttrs' (
      name: command:
        mkAlias {inherit pkgs name command prefix sep;}
    ) (removeAttrs set exclude);

  mkAliases = aliases:
    concatStringsSep "\n" (
      mapAttrsToList
      (name: value: "alias ${name}=${escapeShellArg value}")
      aliases
    );
in {
  inherit
    mkAlias
    mkAliases
    resolveBin
    resolveBins
    mkBin
    mkBins
    mkCmds
    mkVr3n
    ;
}
