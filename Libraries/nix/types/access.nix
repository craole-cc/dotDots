{_, ...}: let
  meta = let
    doc = ''
      # Style Types

      Reusable NixOS option types for style/visual configuration.

      ## Types

      - `opacity.core`  - submodule for NixOS-layer opacity config (terminal, popups)
      - `opacity.home`  - submodule for home-manager-layer opacity config (terminal, popups)

    '';
    exports = {
      local = {inherit headOf;};
      alias = {
        firstItem = headOf;
      };
    };
  in {inherit doc exports;};
  inherit (_.attrsets.access) attrNames;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) optionals;
  inherit (_.types.access) typeOf;
  inherit (_.strings.access) substring;

  headOf = val: let
    msg = {
      isNull = "headOf: value is null";
      isEmpty = "headOf: collection or string is empty";
      unsupported = "headOf: argument must be an attrset, list, string, or int (got ${typeOf val})";
    };

    kind = typeOf val;
    attrs =
      optionals (kind == "set") (attrNames val);
    str =
      if kind == "int"
      then toString val
      else val;
  in
    if val == null
    then throw msg.isNull
    else if kind == "set"
    then
      if attrs == []
      then throw msg.isEmpty
      else head attrs
    else if kind == "list"
    then
      if val == []
      then throw msg.isEmpty
      else head val
    else if kind == "string" || kind == "int"
    then
      if str == ""
      then throw msg.isEmpty
      else substring 0 1 str
    else throw msg.unsupported;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
