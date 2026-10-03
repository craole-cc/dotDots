{
  lib,
  trivial,
  ...
}: let
  inherit (lib.strings) concatStringsSep substring toUpper;
  inherit (lib.lists) filter foldl' head tail map toList;
  inherit (trivial) isNotEmpty;

  #> Render a dotted path list as a string, e.g. ["paths" "roots" "src"] -> "paths.roots.src"
  showPath = path: concatStringsSep "." path;

  /**
  Upper-case the first character of a string, leaving the rest unchanged.

  # Inputs

  `text`
  : String to capitalize. Must be non-empty (an empty string will error,
    since `substring 0 1 ""` is `""` and `toUpper ""` is fine, but callers
    relying on a non-empty result should check first).

  # Type

  ```
  capitalize :: String -> String
  ```

  # Example

  ```nix
  capitalize "nixos"  # => "Nixos"
  capitalize "Nix"    # => "Nix"
  ```
  */
  capitalize = text:
    toUpper (substring 0 1 text) + substring 1 (-1) text;

  mkPath = root: stems:
    concatStringsSep "/" (
      map toString (
        filter isNotEmpty (
          (toList root) ++ (toList stems)
        )
      )
    );
  mkPathLiteral = root: stems: let
    parts = filter isNotEmpty ((toList root) ++ (toList stems));
  in
    if parts == []
    then ""
    else
      foldl'
      (acc: part: acc + "/${toString part}")
      (head parts)
      (tail parts);
in {
  inherit (builtins) hashString;
  inherit
    capitalize
    showPath
    mkPath
    mkPathLiteral
    ;
}
