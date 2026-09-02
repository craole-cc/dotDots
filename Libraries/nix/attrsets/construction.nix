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
  inherit (_.lists.access) elemAt length;
  inherit (_.types.predicates) isBool isList;

  # Curried helper for conditional attribute pairs
  optionalAttr = predicate: name: value: let
    # Auto-coerce non-booleans: non-null and non-empty attrsets evaluate to true
    condition =
      if isBool predicate
      then predicate
      else predicate != null && (!isAttrs predicate || predicate != {});
  in
    optionalAttrs (condition && value != null) {
      "${name}" = value;
    };

  # Single-argument constructor
  asAttrs = arg: let
    isListArg = isList arg;
    isKwargs =
      isAttrs arg
      && (arg ? __condition || arg ? __name || arg ? __value);

    positional = {
      # Extract positional list [ condition name value ]
      condition =
        if isListArg && length arg > 0
        then elemAt arg 0
        else true;
      name =
        if isListArg && length arg > 1
        then elemAt arg 1
        else null;
      value =
        if isListArg && length arg > 2
        then elemAt arg 2
        else null;
    };

    # Auto-coerce condition
    resolved = {
      condition = let
        raw =
          if isListArg
          then positional.condition
          else
            (
              if isKwargs
              then arg.__condition or true
              else true
            );
      in
        if isBool raw
        then raw
        else raw != null && (!isAttrs raw || raw != {});

      name =
        if isListArg
        then positional.Name
        else
          (
            if isKwargs
            then arg.__name or null
            else null
          );

      args =
        if isKwargs
        then removeAttrs arg ["__condition" "__name" "__value"]
        else arg;

      value =
        if isListArg
        then
          if length arg > 2
          then positional.value
          else true
        else if isKwargs
        then
          arg.__value or (
            if resolved.args != {}
            then resolved.args
            else if resolved.name != null
            then true
            else resolved.args
          )
        else arg;

      hasValue =
        if resolved.name != null
        then resolved.value != null
        else isAttrs resolved.value && resolved.value != {};
    };
  in
    with resolved;
      optionalAttrs (condition && hasValue) (
        if name != null
        then {"${name}" = value;}
        else args
      );
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }
