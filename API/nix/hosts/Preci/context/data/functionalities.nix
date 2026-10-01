{
  lib,
  host ? {},
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  resolve = functionalities: genAttrs functionalities (_: true);
  resolved = resolve (host.functionalities or {});
in {inherit resolve resolved;}
