{_, ...}: let
  meta = let
    doc = ''
      Style enums (Layer 4).

      Converts the style registry into typed enums, recursively
      walking nested registry trees and wrapping leaf sets with `mkEnum`.

      Provides pre-built enums for icons and cursors.

      Depends on: style.filters style.registry lists.construction.
    '';
    functions = {inherit all toEnums;};
    exports = {
      local = all // functions;
      alias = {
        toStyleEnums = toEnums;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) mkEnum;
  inherit (_.style.filters.queries) icons cursors;
  inherit (_.style.registry) isRegistryAttrset;

  toEnums = input:
    if isRegistryAttrset input
    then mkEnum {values = input; nullable = true;}
    else mapAttrs (_: toEnums) input;

  all = {
    icons   = toEnums icons.all;
    cursors = toEnums cursors.all;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
