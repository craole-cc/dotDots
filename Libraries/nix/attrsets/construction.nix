{_, ...}: let
  meta = let
    doc = ''
    '';
    functions = {
      inherit
        optionalAttr
        ;
    };
    exports = {
      local = functions;
      store = functions;
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.construction) optionalAttrs;

  optionalAttr = name: value:
    optionalAttrs (value != null) {${name} = value;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }
