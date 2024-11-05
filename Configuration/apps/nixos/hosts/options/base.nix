{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.nixpkgs.localSystem) isEfi;

  inherit (lib.attrsets)
    filterAttrs
    attrNames
    attrValues
    mapAttrs
    isAttrs
    ;
  inherit (lib.lists)
    length
    head
    elem
    elemAt
    ;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings)
    concatStringsSep
    fileContents
    stringLength
    substring
    ;
  inherit (lib.types)
    nonEmptyStr
    package
    nullOr
    bool
    str
    strMatching
    float
    enum
    attrs
    listOf
    int
    raw
    submodule
    nonEmptyListOf
    ;
  inherit (lib.filesystem) pathIsRegularFile;

  #| Extended Imports
  inherit (config) DOTS;
  base = "hosts";
  src = DOTS.sources.${mod};
  cfg = DOTS.${base}.${mod};

  inherit (DOTS.modules) host;
  inherit (DOTS.sources.host.configuration) attrs;
in
{
  options.DOTS.${base} = mkOption {
    description = "";
    default = mapAttrs (name: path: host name path) attrs;
  };
}
