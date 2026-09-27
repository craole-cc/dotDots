{lib, ...}: let
  inherit (lib.strings) concatStringsSep substring toUpper;

  inherit (builtins) hashString;

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
in {inherit capitalize hashString showPath;}
