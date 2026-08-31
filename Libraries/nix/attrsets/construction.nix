{_, ...}: let
  meta = let
    doc = "";
    functions = {
      inherit
        optionalAttr
        asAttrs
        ;
    };
    exports = {
      local = functions;
      store = functions;
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.construction) optionalAttrs;
  optionalAttr = name: value: optionalAttrs (value != null) {${name} = value;};

  asAttrs = arg: let
    isKwargs =
      isAttrs arg
      && (arg ? condition || arg ? name || arg ? value);
    condition =
      if isKwargs
      then arg.condition or true
      else true;
    name =
      if isKwargs
      then arg.name or null
      else null;
    value =
      if isKwargs
      then arg.value or arg
      else arg;
  in
    optionalAttrs
    (condition && (isAttrs value && value != {}))
    (
      if name != null
      then {"${name}" = value;}
      else value
    );
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }
