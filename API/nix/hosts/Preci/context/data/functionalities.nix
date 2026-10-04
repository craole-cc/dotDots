{
  lix,
  host ? {},
  ...
}: let
  inherit (lix.attrsets) genAttrs isAttrs;
  inherit (lix.lists) isList;
  inherit (lix.trivial) typeOf;

  #? `host.functionalities` is whatever `libraries.schemas.functionalities`
  #? resolved, which is a record carrying both views:
  #?
  #?   .names  the list of names
  #?   .set    the attrset of names
  #?   .isList the shape the host declared
  #?
  #? An older hand-written resolver put the bare list there instead, and a
  #? hand-written host may still carry a raw list or attrset. All three are
  #? accepted, so this module does not care which generation produced the host.
  names = value:
    if value == null
    then []
    else if isAttrs value && value ? names
    then value.names
    else if isList value
    then value
    else if isAttrs value
    then builtins.attrNames value
    else throw "context data functionalities: expected a list, an attrset, or a resolved record, but got ${typeOf value}";

  #? The attrset view, for membership tests that read better against an
  #? attrset than against a list scan.
  set = value: genAttrs (names value) (_: true);

  value = host.functionalities or {};
in {
  inherit names set;
  #? The list of names. `data/default.nix` and `data/principals.nix` bind this
  #? to `functionalities`, so the name is unchanged for existing consumers; the
  #? attrset view is available as `.set`.
  resolved = names value;
}
