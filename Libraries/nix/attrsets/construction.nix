{_, ...}: let
  meta = let
    doc = "";
    functions = {inherit optionalAttr asAttrs;};
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

  /**
  Construct a single named attribute when the predicate is true and the value
  is not null; otherwise return `{}`. Arguments are curried as
  `optionalAttr predicate name value`.

  Boolean predicates are used directly. For other predicates, null and `{}`
  are false; all other values, including `[]`, `""` and `0`, are true.
  Empty lists and strings are also retained as values. To omit an empty list,
  use an explicit predicate such as `after != []`.

  # Examples

  ```nix
  optionalAttr true "port" 8080
  # => { port = 8080; }

  optionalAttr false "port" 8080
  # => {}

  optionalAttr true "port" null
  # => {}

  optionalAttr {} "enabled" true
  # => {}

  optionalAttr [] "after" []
  # => { after = []; }

  let after = [ "network.target" ]; in
  optionalAttr (after != []) "after" after
  # => { after = [ "network.target" ]; }

  optionalAttr ([] != []) "after" []
  # => {}
  ```
  */
  optionalAttr = predicate: name: value: let
    #? Auto-coerce non-booleans: non-null and non-empty attrsets evaluate to true
    condition =
      if isBool predicate
      then predicate
      else predicate != null && (!isAttrs predicate || predicate != {});
  in
    optionalAttrs (condition && value != null) {
      "${name}" = value;
    };

  /**
  Construct an optional attribute set from a single argument.

  A plain attribute set passes through unchanged. Use `__condition`, `__name`
  and `__value` to control inclusion, wrap a value under a name, or supply an
  explicit value. These reserved keys are removed from the returned attributes.
  The condition defaults to true; null and an empty attribute set are false,
  while other non-Boolean conditions are true.

  With `__name`, the value defaults to the remaining attributes, or true when
  none remain. A null named value is omitted. Without `__name`, the remaining
  attributes are returned only when the resolved value is a non-empty attribute
  set; `__value` controls that check but does not replace those attributes.

  Positional lists use `[ condition name value ]`, with the value defaulting to
  true.

  # Examples

  ```nix
  asAttrs { enabled = true; }
  # => { enabled = true; }

  asAttrs { __condition = false; enabled = true; }
  # => {}

  asAttrs { __name = "enabled"; }
  # => { enabled = true; }

  asAttrs { __name = "service"; port = 8080; }
  # => { service = { port = 8080; }; }

  asAttrs { __name = "port"; __value = 8080; }
  # => { port = 8080; }

  asAttrs { __name = "port"; __value = null; }
  # => {}
  ```
  */
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
        then positional.name
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
