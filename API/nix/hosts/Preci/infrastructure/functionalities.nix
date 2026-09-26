{lix, ...}: let
  inherit (lix.attrsets) genAttrs;

  resolve = functionalities:
    genAttrs functionalities (_: true);
in {
  inherit resolve;
}
