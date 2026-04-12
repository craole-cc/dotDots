{_, ...}: let
  meta = let
    doc = ''
      Set-membership predicates (Layer 2).

      Provides boolean probes over an attribute set of application entries,
      answering "does any entry in this set carry field X?" questions.
      Both predicates scan the values of `set` and short-circuit to `true`
      as soon as one qualifying entry is found.

      Depends on: applications.primitives
    '';

    functions = {
      inherit hasField hasListField;
    };
    exports = {
      local = functions;
      alias = {};
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrValues;
  inherit (_.lists.predicates) isList;
  inherit (_.lists.selection) filter;
  inherit (_.applications.primitives) toValue;

  /**
    Return `true` when at least one entry in `set` has a non-null value at
    `field`.

    # Type
  ```nix
    hasField :: {
      field :: string,
      set   :: AttrSet,
    } -> bool
  ```

    # Examples
  ```nix
    hasField {
      field = "color";
      set   = { a = { color = "red"; }; b = { color = null; }; };
    }
    # => true

    # All entries have a null or absent field
    hasField {
      field = "color";
      set   = { a = {}; b = { color = null; }; };
    }
    # => false
  ```
  */
  hasField = {
    field,
    set,
  }:
    filter (a: toValue {inherit field;} a != null) (attrValues set) != [];

  /**
    Return `true` when at least one entry in `set` has a list value at `field`.

    Entries where the field is absent or holds a non-list value do not
    contribute; only actual list values satisfy the predicate.

    # Type
  ```nix
    hasListField :: {
      field :: string,
      set   :: AttrSet,
    } -> bool
  ```

    # Examples
  ```nix
    hasListField {
      field = "tags";
      set   = { a = { tags = [ "x" ]; }; b = { tags = "y"; }; };
    }
    # => true   # a's value is a list; b's scalar value does not contribute

    # Field present on all entries but never as a list
    hasListField {
      field = "tags";
      set   = { a = { tags = "x"; }; b = { tags = null; }; };
    }
    # => false
  ```
  */
  hasListField = {
    field,
    set,
  }:
    filter (a: isList (toValue {inherit field;} a)) (attrValues set) != [];
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
